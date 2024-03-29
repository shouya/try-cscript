# Lexer for racc, cscript project
# Shou Ya, 8 Apr morning
#
# vim filetype=ruby

require 'strscan'
require_relative 'cscript'

module CScript
    class ScannerError < CScriptError
    end
    class Scanner
        include Enumerable

        attr :state, :line_no, :column_no
        attr :scanner
        attr :filename
        attr :text
        attr_reader :parser

=begin
        attr_accessor :state
        attr_accessor :lineno
        attr_accessor :file
=end

        class << self
            attr_reader :rules
            def rule(mtch, state = nil, &block)
                @rules ||= []
                @rules << [mtch, state, block]
            end
            def char_class_rule(str, state = nil, &block)
                rule(Regexp.new("[#{Regexp.escape(str)}]"),
                     state, &block)
            end
            def keyword_rule(keyword, state = nil, &block)
                rule(Regexp.new("\\b#{keyword.to_s}\\b"), state, &block)
            end
            def symbol_rule(symbol, state = nil, &block)
                rule(Regexp.new(Regexp.escape(symbol)), state, &block)
            end
        end

        # Basic elements
        rule(/\d+/)                 { [:INTEGER, @text.to_i] }
        rule(/\"([^\"]|\\[nt\"])*\"/)       { [:STRING, parse_str(@text)] }

        # Comments
        rule(%r[\/\*])              { set_state :COMM; :PASS }
        rule(%r[\*\/], :COMM)       { set_state nil; :PASS }
        rule(/\n/, :COMM)           { :PASS }
        rule(/./, :COMM)            { :PASS }

        # Comparisons
        symbol_rule('<=')           { [:RELATION, :<=] }
        symbol_rule('<')            { [:RELATION, :<] }
        symbol_rule('>=')           { [:RELATION, :>=] }
        symbol_rule('>')            { [:RELATION, :>] }
        symbol_rule('==')           { [:EQUALITY, :==] }
        symbol_rule('!=')           { [:EQUALITY, :!=] }

        # Multi-character operators
        symbol_rule('&&')                  { [:LOGAND] }
        symbol_rule('||')                  { [:LOGOR] }

        # Keywords
        keyword_rule(:if)           { [:IF] }
        keyword_rule(:else)         { [:ELSE] }
        keyword_rule(:while)        { [:WHILE] }
        keyword_rule(:return)       { [:RETURN] }
        keyword_rule(:break)        { [:BREAK] }
        keyword_rule(:last)         { [:BREAK] }
        keyword_rule(:continue)     { [:NEXT] }
        keyword_rule(:next)         { [:NEXT] }
        keyword_rule(:redo)         { [:REDO] }
        keyword_rule(:def)          { [:DEF] }
        keyword_rule(:true)         { [:BOOL, true] }
        keyword_rule(:false)        { [:BOOL, false] }
        keyword_rule(:global)       { [:GLOBAL] }

        # Debugging macro
        keyword_rule(:EMIT)         { [:EMIT] }     if $CS_DEBUG

        # Single-character symbols
        char_class_rule('+-*/%;,.:()[]{}!?&|^~=')      { [@text] }

        # Name
        rule(/[a-zA-Z_]\w*/)        { [:NAME, @text] }

        # Spaces / Newlines
        rule(/\r\n|\r|\n/)          { inc_line; :PASS }
        rule(/\s+/)                 { :PASS }


        public
        def initialize(parser)
            @parser = parser
        end


        def each
            while (token = next_token) != [false, false] do
                yield token
            end
        end

        private
        def set_data_and_initialize(string)
            @scanner = StringScanner.new(string)
            @state = nil

            @line_no = 0
            @column_no = 0
            @filename = '<unknown>'
            @text = ''
        end


        public
        def scan_stdin
            set_data_and_initialize($stdin.read)
            @filename = '<stdin>'
        end

        def scan_file(filename)
            set_data_and_initialize(File.read(filename))
            @filename = filename
        end

        def scan_string(string)
            set_data_and_initialize(string)
            @filename = '<string>'
        end


        private
        def inc_line
            @line_no += 1
            @column_no = @scanner.pos
        end

        def set_state(new_state)
            @state, old_state = new_state, @state
            old_state
        end

        def parse_str(text)
            result = ''
            pattern = %r[(\\[nt\\\/\|]|.)] # currently handles \
            # \n, \t, \\, \/, \| only
            text[1..-2].scan(pattern) do |(m)|
                if m[0] == "\\" then
                    result << eval(%["#{m}"])
                else
                    result << m.to_s
                end
            end
            result
        end

=begin
        # Another easier way but not quite safe as this
        # and it will unexcepted execute stuff like '#{XXXX}'
        result = proc {
            $SAFE = 4
            eval text
            }.call
=end


        public
        def column
            return @scanner.pos - @column_no
        end

        def next_token
            action = nil
            action = @parser.preprocess if @state == nil
            return action unless action == :PASS

            until (action = match_and_deal) != :PASS
                action = @parser.preprocess if @state == nil
                return action unless action == :PASS
            end
            action
        end

        def match_and_deal
            return [false, false] if @scanner.eos?

            state_filtered = self.class.rules.select {|x| x[1] == @state }
            rule = state_filtered.detect {|x| @scanner.match? x[0] }
            report_error 'Unmatched token' if rule.nil?

            @text = @scanner.scan(rule[0])

            result = self.instance_eval &rule[2]

            report_error 'Unkown return %s from rule %s' % [result.inspect,
                rule[0]] unless Array === result or result == :PASS

            if Array === result and result.length == 1
                return result.push nil
            elsif Array === result and result.length == 2
                return result
            elsif result == :PASS
                return :PASS
            else
                report_error "Invalid result #{result.inspect}"
            end
        end

        private
        def report_error(msg)
            raise ScannerError,
                msg << " at #{report_location}.",
                caller[1..-1]
        end


        def report_location
            f, l, c = location
            "#{f}(#{l}:#{c})"
        end

        public
        def location
            [@filename, @line_no, column]
        end

    end
end

=begin To be added
    rule('for')                 { [:FOR] }
    rule('do')                  { [:DO] }
    rule('case')                { [:CASE] }
    rule('switch')              { [:SWITCH] }
    rule('default')             { [:DEFAULT] }
    rule('in')                  { [:IN] }
    rule('struct')
    rule('enum')
    rule('lambda')
    rule('null')
    rule('auto')
    rule('extern')
    rule('static')
    rule('++')
    rule('--')
    rule('<<')
    rule('>>')
=end

