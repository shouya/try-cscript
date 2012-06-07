require 'sinatra'
require 'erb'
require 'json'


$CS_DEBUG = true
require_relative '../cscript/cscript'


set :root, File.dirname(__FILE__)

get '/' do
    erb :index
end

post '/syntaxtree' do
    parser = CScript::Parser.new
    parser.scan_string(request.POST['data'])

    tree = JSON.pretty_generate(parser.do_parse.as_json)
    erb :syntax_tree, :locals => { :tree => tree }
end

post '/run' do
    json = CScript::Parser.parse_string(request.POST['data'])
    prog = CScript::Program.new
    prog.load_json(json)
    prog.run
    erb :result, :locals => { :results => prog.emissions }
end



