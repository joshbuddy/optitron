class Optitron
  class Response
    attr_reader :params_array, :args, :params, :args_with_tokens, :errors
    attr_accessor :command
    def initialize(tokens)
      @tokens = tokens
      @params_array = []
      @args_with_tokens = []
      @args = []
      @command = nil
      @errors = Hash.new{|h,k| h[k] = []}
      @params = {}
    end
    
    def add_error(field, type)
      @errors[field] << type
    end
    
    def compile_params
      @params_array.each do |(key, value)|
        begin
          params[key.name] = key.validate(value)
        rescue
          add_error(key.name, 'invalid')
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
          add_error(arg.name, 'invalid')
          tok.is_a?(Array) ? tok.map{ |t| t.val } : tok.val
        end
      }
      @args.flatten!
      unless @tokens.empty?
        @tokens.select{|t| t.respond_to?(:name)}.each do |named_token|
          @tokens.delete(named_token)
          add_error(named_token.name, 'unrecognized')
        end
        
        if @errors.empty?
          @tokens.each do |token|
            add_error(token.val, 'unrecognized')
          end
        end
      end
    end

    def dispatch(obj)
      if valid?
        dispatch_args = params.empty? ? args : args + [params]
        obj.send(command.to_sym, *dispatch_args)
      else
        raise
      end
    end
    
    def valid?
      @errors.empty?
    end
  end
end