$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'optitron'
require 'phocus'

class Object
  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end
    result
  end
end