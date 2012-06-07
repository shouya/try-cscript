
require_relative '../cscript'

require 'pp'

parser = CScript::Parser.new
parser.scan_stdin
tree = parser.do_parse


pp tree.as_json


