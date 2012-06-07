require 'sinatra'

require_relative '../cscript/cscript'


set :root, File.dirname(__FILE__)

get '/' do
    '<h1>Hello World</h1>'
end

post '/syntaxtree' do
    content_type :json
    parser = CScript::Parser.new
    parser.scan_string(request.body.read)
    #parser.scanner.filename = '<fromweb>'

    parser.do_parse.to_json
end


