$LOAD_PATH << 'lib'
require 'optitron'

parser = Optitron::Parser.new { parser.literal('test') }
parser.ordered('test').mandatory.match('test')
parser.ordered('test2').mandatory.match('test2')
#
#p parser.parse(['test'])
#p parser.parse(['test', 'test2'])

parser = Optitron::Parser.new
parser.ordered('test').mandatory.match('test')
parser.named('a').alias('after').string.mandatory
#p parser.parse(['test', '--after=val'])
#p parser.parse(['test', '-a', 'val'])
p parser.parse(['--after=val', 'test'])
p parser.parse(['-a', 'val', 'test'])
