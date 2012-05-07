require 'drb/drb'
require ENV["TM_SUPPORT_PATH"] + "/lib/tm/executor"
require ENV["TM_SUPPORT_PATH"] + "/lib/tm/save_current_document"

TextMate.save_current_document

is_test_script = ENV["TM_FILEPATH"] =~ /(?:\b|_)(?:tc|ts|test)(?:\b|_)/ or
  File.read(ENV["TM_FILEPATH"]) =~ /\brequire\b.+(?:test\/unit|test_helper)/

SPORK_SERVER_URI="druby://localhost:#{ENV["SPORK_PORT"] || 8988}"

def spork?
  # return false
  @spork ||= lambda{
    return false if ENV['SPORK_TESTUNIT'].nil?
    begin
      spork_server = DRbObject.new_with_uri(SPORK_SERVER_URI)
      if spork_server.respond_to?(:run)
        return true
      end
    rescue Exception => e
      return false
    end
  }.call
end

cmd = spork? ? ['testdrb'] : [ENV['TM_RUBY'] || 'ruby', '-rcatch_exception']

if is_test_script and not ENV['TM_FILE_IS_UNTITLED']
  path_ary = (ENV['TM_ORIG_FILEPATH'] || ENV['TM_FILEPATH']).split("/")
  if index = path_ary.rindex("test")
    test_path = File.join(*path_ary[0..-2])
    test_parent_path = File.join(*path_ary[0..(path_ary.rindex('test'))])
    lib_path  = File.join( *( path_ary[0..-2] +
                              [".."] * (path_ary.length - index - 1) ) +
                              ["lib"] )
    if File.exist? lib_path
      cmd << "-I#{lib_path}:#{test_path}:#{test_parent_path}"
    else
      lib_path = File.join(File.dirname(test_parent_path), 'lib')
      cmd << "-I#{lib_path}:#{test_path}:#{test_parent_path}" if File.exist? lib_path
    end
  end
end

if spork?
  cmd << "-n#{ARGV[1].gsub(/--name=/, '')}"
  script_args = []
else
  script_args = ARGV + ['-v']
end

cmd << ENV["TM_FILEPATH"]

def start_of_test?(line)
  !!(line =~ /\s*test:/)
end

def end_of_test?(line)
  !!(line =~ /[.EF]: \([\d.]+\)/)
end

def last_line?(line)
  !!(line =~ /tests.*assertions.*failures.*errors/)
end

#test: .bulk_shipment_items distributor_return should include ship_to_distributors. :.: (0.200692)
# 1:"test: "  --  throw away
# 2:".bulk_shipment_items distributor_return should include ship_to_distributors"  --  test name
# 3:". :"  --  throw away
# 4:""  --  any puts in the test
# 5:".:"  --  throw away
# 6:"."  --  test result . or E or F
# 7:"0.200692"  --  duration
def test_parts_with_duration(string)
  result = string.match(/\A\s*(test:\s*)(.*?)(\.\s*:)(.*)(([.EF]):)\s*\(([\d.]+)\)\s*\z/m)
  
  if result.nil?
    nil
  else
    [result[2], result[4].sub(/^\s+/, ''), result[6], result[7]]
  end
end

# str = "test: schema should truth. (RedemptionTest): .\n" A 
# 1:"test: "  --  throw away
# 2:"schema should truth. (RedemptionTest)"  --  test name
# 3:":"  --  throw away
# 4:""  --  any puts in the test
# 5:"."  --  test result . or E or F
def test_parts_without_duration(string)
  result = string.match(/\A\s*(test:\s*)(.*?)(\.\s*:)(.*)([.EF])\s*\z/m)
  
  if result.nil?
    nil
  else
    [result[2], result[4], result[5], nil]
  end
end

# str = "test: schema should truth. (RedemptionTest): .\n" A 
# str = " test: schema should truth. :\t\t\t\tdebug\n" A 
def format_output(string)
  test_name, test_puts, test_result, test_duration = if string =~ /(([.EF]):)\s*\(([\d.]+)\)\s*\z/m
    test_parts_with_duration(string)
  else
    test_parts_without_duration(string)
  end
  
  if test_name.nil?
    out = htmlize(string)
  else
    out = "&nbsp;&nbsp;#{format_test_result(test_result)}&nbsp;&nbsp;#{format_test_name(test_name, test_result)}"
    out << ":&nbsp;(#{test_duration})" if test_duration
    out << "<br/>"
    out << %Q!<div style="background-color:#E6E6E6; padding: 5px 10px">#{htmlize(test_puts)}</div>! unless test_puts.strip.empty?
  end
  
  out
end

def format_test_name(test_name, result)
  out = test_name
  out = %Q!<span style="font-weight:bold">#{test_name}</span>! unless result == '.'
  out
end

def format_test_result(result)
  result.gsub(/[EF]+/, "<span style=\"color: red; font-weight:bold\">\\&</span>").gsub(/\.+/, "<span style=\"color: green; font-weight:bold\">\\&</span>")
end

test_script_buffer = ''
test_script_output = ''
past_test_run = false #set to true once tests have been completed and now printing the errors/failures


class TestResultParser
  
  attr_reader :buffer, :in_buffer
  alias :in_buffer? :in_buffer
  
  def initialize
    @buffer = []
    @in_buffer = false
  end
  
  def test_result_line?(line)
    line =~ /^\w+#test[:_]/ || in_buffer?
  end
  
  def process_line(line)    
    if line =~ /^\w+#test[:_]/
      @buffer = [line]
      @in_buffer = true
    elsif in_buffer?
      @buffer << line
    end
    
    if line =~ /= [\.EF]$/
      @in_buffer = false
      
      all_lines = buffer.join
      match = all_lines.match(/(.*?(\.  = ))(.*?)([\d\.]+ . = [\.EF])\Z/m)
      
      if match
        test_result = match[1] + match[4]
        test_puts = match[3]
                
      else
        test_result = all_lines
      end
      
      style = if line =~ /(E|F)$/
        'color:red; font-weight:bold;'
      else
        'color:green;'
      end
      
      test_has_puts = !(test_puts.nil? || test_puts.strip == "")
      
      out = "<div style=\"#{style}padding: 1px 9px 0 9px;#{'background-color: rgba(0, 0, 0, 0.2); border-top-left-radius: 5px; border-top-right-radius: 5px;' if test_has_puts}\">#{test_result}</div>"
      out << "<div style=\"color: #141414; background-color: rgba(0, 0, 0, 0.2); padding: 2px 9px; border-bottom-left-radius: 5px; border-bottom-right-radius: 5px; margin-bottom: 5px\">#{htmlize(test_puts)}</div>" if test_has_puts
      out
    else
      ""
    end
  end
end

trp = TestResultParser.new

TextMate::Executor.run(cmd, :version_args => ["--version"], :script_args => script_args) do |str, type|  
  case type
  when :out
    if is_test_script and str =~ /\A[.EF]+\Z/
      format_test_result(htmlize(str)) + "<br style=\"display: none\"/>"
    elsif is_test_script
      out = ""
      [str].flatten.each do |line|        
        out << if trp.test_result_line?(line)
          trp.process_line(line)
        elsif line =~ /^\d+ tests, \d+ assertions, (\d+) failures, (\d+) errors\b.*/  # test summary
          "<span style=\"color: #{$1 + $2 == "00" ? "green" : "red"}\">#{$&}</span><br/>"
        elsif line =~ /([^\w\/])([\w\.\/\-@]+.rb):(\d+)(.*)/  # backtrace - provide linkage
          prepend, file, line_number, append = $1, $2, $3, $4
          file = File.join(ENV['TM_PROJECT_DIRECTORY'].to_s, file) unless file =~ /^\//
          color, decoration = if ENV['TM_PROJECT_DIRECTORY'].nil? or file.include?(ENV['TM_PROJECT_DIRECTORY'] + '/test')
            ['blue', 'underline']
          else
            ['black', 'none']
          end
          "#{prepend}<a style=\"color: #{color}; text-decoration: #{decoration};\" href=\"txmt://open?url=file://#{e_url(file)}&amp;line=#{line_number}\">#{file}:#{line_number}</a>#{append}<br/>"
        else
          htmlize(line)
        end
      end

      out
    else
      htmlize(str)
    end
  when :err
    "<span style=\"color: red\">#{htmlize str}</span>"
  end
end