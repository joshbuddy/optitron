class Optitron
  class Parser
    attr_accessor :target
    attr_reader :commands, :options, :args, :short_opts
    
    def initialize
      @options = []
      @commands = []
      @args = []
      @short_opts = {}
      @help = Help.new(self)
    end

    def help
      @help.generate
    end

    def parse(argv = ARGV)
      tokens = Tokenizer.new(self, argv).tokens
      response = Response.new(self, tokens)
      options = @options 
      args = @args
      unless @commands.empty?
        potential_cmd_toks = tokens.select { |t| t.respond_to?(:lit) }
        if cmd_tok = potential_cmd_toks.find { |t| @commands.assoc(t.lit) }
          tokens.delete(cmd_tok)
          response.command = cmd_tok.lit
          options += @commands.assoc(cmd_tok.lit).last.options
          args = @commands.assoc(cmd_tok.lit).last.args
        elsif !potential_cmd_toks.empty? && @target.respond_to?(:command_missing)
          command = potential_cmd_toks.first.lit
          response.command = 'command_missing'
          @commands << [response.command, Option::Cmd.new(response.command)]
          @commands.assoc(response.command).last.options.insert(-1, *tokens.select { |t| !t.respond_to?(:lit) }.map { |t|
            t.is_a?(Tokenizer::Named) ?
              Option::Opt.new(t.name, nil, :short_name => t.name) :
              Option::Opt.new(t.name, nil, :type => (t.value ? :string : :boolean))
          })
          @commands.assoc(response.command).last.args <<
            Option::Arg.new('command', 'Command name', :type => :string) <<
            Option::Arg.new('args', 'Command arguments', :type => :greedy)
          options += @commands.assoc(response.command).last.options
          args = @commands.assoc(response.command).last.args
        else
          potential_cmd_toks.first ?
            response.add_error('an unknown command', potential_cmd_toks.first.lit) :
            response.add_error('unknown command')
        end
      end
      parse_options(tokens, options, response)
      parse_args(tokens, args, response)
      response.validate
      response
    end

    def parse_options(tokens, options, response)
      options.each do |opt|
        response.params[opt.name] = opt.default if opt.has_default?
        if opt_tok = tokens.find { |tok| opt.match?(tok) }
          opt_tok_index = tokens.index(opt_tok)
          opt.consume(response, tokens)
        elsif opt.required?
          response.add_error("required", opt.name)
        end
      end
    end
    
    def parse_args(tokens, args, response)
      args.each { |arg| arg.consume(response, tokens) }
    end
  end
end
