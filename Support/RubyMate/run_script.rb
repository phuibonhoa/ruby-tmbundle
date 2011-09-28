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
    begin
      return false if ENV['SPORK_TESTUNIT'].nil?
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
  test = ARGV.last.gsub(/--name=/, '') if ARGV.last and ARGV.last.match(/--name=/)
  cmd << "-n#{test}" if test
  script_args = []
else
  script_args = ARGV
end

cmd << ENV["TM_FILEPATH"]

TextMate::Executor.run(cmd, :version_args => ["--version"], :script_args => script_args) do |str, type|
  case type
  when :out
    if is_test_script and str =~ /\A[.EF]+\Z/
      htmlize(str).gsub(/[EF]+/, "<span style=\"color: red\">\\&</span>").gsub(/\.+/, "<span style=\"color: green\">\\&</span>") + "<br style=\"display: none\"/>"
    elsif is_test_script
      out = [str].flatten.map do |line|
        if line =~ /^(\s+)(\S.*?):(\d+)(?::in\s*`(.*?)')?/
          indent, file, line, method = $1, $2, $3, $4
          url, display_name = '', 'untitled document';
          unless file == "-"
            indent += " " if file.sub!(/^\[/, "")
            file = File.join(ENV['TM_PROJECT_DIRECTORY'], file) unless file =~ /^\//
            url = '&amp;url=file://' + e_url(file)
            display_name = File.basename(file)
          end
          "#{indent}<a class='near' href='txmt://open?line=#{line + url}'>" +
          (method ? "method #{CGI::escapeHTML method}" : '<em>at top level</em>') +
          "</a> in <strong>#{CGI::escapeHTML display_name}</strong> at line #{line}<br/>"
        elsif line =~ /\A\s*test:.*?\.\s*\(.*?\):\s*[.EF]\n?\Z/
          htmlize(line.chomp).gsub(/([EF])\Z/, "<span style=\"color: red\">\\1</span>").gsub(/(\.)\Z/, "<span style=\"color: green\">\\1</span>") + "<br/><br style=\"display: none\"/>"
        elsif line =~ /\A\s*(test:.*?\.\s*\(.*?\):\s*)(.*)\Z/m
          test_header, test_output = $1, $2
          htmlize(test_header.chomp) + "<br/><br style=\"display: none\"/>" + htmlize(test_output) + "<br/><br style=\"display: none\"/>"
        elsif line =~ /(\[[^\]]+\]\([^)]+\))\s+\[([\w\_\/\.]+)\:(\d+)\]/
          spec, file, line = $1, $2, $3, $4
          file = File.join(ENV['TM_PROJECT_DIRECTORY'], file) unless file =~ /^\//
          "<a style=\"color: blue;\" href=\"txmt://open?url=file://#{e_url(file)}&amp;line=#{line}\">#{spec}</a>:#{line}<br/>"
        elsif line =~ /(.*?:)?([\w\_ ]+).*\[([\w\_\/\.]+)\:(\d+)\]/
          method, file, line = $2, $3, $4
          file = File.join(ENV['TM_PROJECT_DIRECTORY'], file) unless file =~ /^\//
          "<a style=\"color: blue;\" href=\"txmt://open?url=file://#{e_url(file)}&amp;line=#{line}\">#{File.basename(file)}</a>:#{line}<br/>"
        elsif line =~ /^\d+ tests, \d+ assertions, (\d+) failures, (\d+) errors\b.*/
          "<span style=\"color: #{$1 + $2 == "00" ? "green" : "red"}\">#{$&}</span><br/>"
        else
          htmlize(line)
        end
      end
      out.join()
    else
      htmlize(str)
    end
  when :err
    "<span style=\"color: red\">#{htmlize str}</span>"
  end
end