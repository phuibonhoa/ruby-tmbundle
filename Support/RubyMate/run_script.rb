require 'drb/drb'
require 'uri'
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


def format_test_result(result)
  result.gsub(/[EF]+/, "<span style=\"color: red; font-weight:bold\">\\&</span>").gsub(/\.+/, "<span style=\"color: green; font-weight:bold\">\\&</span>")
end


class TestResultParser
  
  attr_reader :buffer, :in_buffer, :printed_header
  attr_accessor :test_file
  alias :in_buffer? :in_buffer
  alias :printed_header? :printed_header
  alias :test_file? :test_file
  
  def initialize(attributes={})
    attributes = {test_file: false}.merge(attributes)
    @buffer = []
    @in_buffer = false
    @printed_header = false
    @test_file = attributes.fetch(:test_file)
  end
  
  def header
    <<-EOT
<link href="file://#{URI.escape ENV['TM_BUNDLE_SUPPORT']}/assets/buttons.css" type="text/css" rel="stylesheet"/>
<style>
  #toggle {
    float:right;
  }

  .red {
    color:red; 
    font-weight:bold;
  }
  
  .green {
    color:green;
  }
  
  .puts {
    color: #141414; 
    background-color: rgba(0, 0, 0, 0.2); 
    padding: 2px 9px; 
    border-bottom-left-radius: 5px; 
    border-bottom-right-radius: 5px; 
    margin-bottom: 5px
  }
  
  .test_name {
    padding: 1px 9px 0 9px;
  }
  
  .puts_header {
    background-color: rgba(0, 0, 0, 0.2); 
    border-top-left-radius: 5px; 
    border-top-right-radius: 5px;
  }
</style>
<div id="toggle" class="btn btn-inverse btn-mini">Hide Passing Tests</div><br/>
<script src="file://#{URI.escape ENV['TM_BUNDLE_SUPPORT']}/assets/jquery-1.6.4.min.js" type="text/javascript"></script>
<script>$('#toggle').toggle(
  function() { $('.green').slideUp(); $('#toggle').removeClass('btn-inverse').addClass('btn-success').text('Show Passing Tests') },
  function() { $('.green').slideDown(); $('#toggle').removeClass('btn-success').addClass('btn-inverse').text('Hide Passing Tests') }
  );
</script>
    EOT
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
      
      css_class = if line =~ /(E|F)$/
        'red'
      else
        'green'
      end
      
      test_has_puts = !(test_puts.nil? || test_puts.strip == "")
      
      out = "<div class=\"#{css_class} test_name #{'puts_header' if test_has_puts}\">#{test_result}</div>"
      out << "<div class=\"#{css_class} puts\">#{htmlize(test_puts)}</div>" if test_has_puts
      out
    else
      ""
    end
  end
  
  def post_filter(output)
    if printed_header? or !test_file?
      output
    else
      @printed_header = true
      header + output
    end
  end
end

trp = TestResultParser.new(:test_file => is_test_script)

if ENV['TM_BUNDLE'] || ENV['TM_RUBY'].to_s =~ /\.rvm/
  bundle_cmd = if ENV['TM_BUNDLE']
    ENV['TM_BUNDLE'] 
  else
    file = File.readlines(ENV['TM_RUBY'])
    ruby_gemset = file.detect { |line| line =~ /source/ }.match(/environments\/([^'"]+)/)[1]
    base_dir = ENV['TM_RUBY'].match(/(.*.rvm\/).*/)[1]
    File.join(base_dir, 'gems', ruby_gemset, 'bin', 'bundle')
  end
    
  cmd = [bundle_cmd, 'exec'] + cmd
end

TextMate::Executor.run(cmd, :version_args => ["--version"], :script_args => script_args) do |str, type|  
  output = case type
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
    if str.include? "activesupport-3.0.10/lib/active_support/dependencies.rb:239:in `block in require': iconv will be deprecated in the future, use String#encode instead."
      ''
    else
      "<span style=\"color: red\">#{htmlize str}</span>"
    end
  end
  
  trp.post_filter(output)
end