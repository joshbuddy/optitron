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

    def parse(args = ARGV)
      tokens = Tokenizer.new(self, args).tokens
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
        else
          puts @help.generate
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