class Optitron
  class Response
    attr_reader :params_array, :args, :params, :args_with_tokens, :errors
    attr_accessor :command
    def initialize(parser, tokens)
      @parser, @tokens = parser, tokens
      @params_array = []
      @args_with_tokens = []
      @args = []
      @command = nil
      @errors = []
      @params = {}
    end
    
    def add_error(type, field = nil)
      @errors << [type, field]
    end
    
    def error_messages
      @errors.map{|(error, field)| field ? "#{field} is #{error}".capitalize : error.capitalize}
    end
    
    def compile_params
      @params_array.each do |(key, value)|
        begin
          params[key.name] = key.validate(value)
        rescue
          add_error('invalid', key.name)
          params[key.name] = value
        end
      end
    end
    
    def validate
      compile_params
      @args = @args_with_tokens.map { |(arg, tok)| 
        begin
          tok.is_a?(Array) ? tok.map{ |t| arg.validate(t.val) } : arg.validate(tok.val)
        rescue
          add_error('invalid', arg.name)
          tok.is_a?(Array) ? tok.map{ |t| t.val } : tok.val
        end
      }
      @args.flatten!
      unless @tokens.empty?
        @tokens.select{|t| t.respond_to?(:name)}.each do |named_token|
          @tokens.delete(named_token)
          add_error('unrecognized', named_token.name)
        end
        
        if @errors.empty?
          @tokens.each do |token|
            add_error('unrecognized', token.val)
          end
        end
      end
    end

    def dispatch
      raise unless @parser.target
      if valid?
        dispatch_args = params.empty? ? args : args + [params]
        @parser.target.send(command.to_sym, *dispatch_args)
      else
        puts @parser.help
        puts "\nErrors:"
        puts error_messages.join("\n")
      end
    end

    def valid?
      @errors.empty?
    end
  end
end