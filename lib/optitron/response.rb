class Optitron
  class Response
    attr_reader :params_array, :args, :params, :args_with_tokens, :errors, :args_hash
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
          validated_value = key.validate(value)
          params[key.name] = validated_value if key.include_in_params?
        rescue
          add_error('invalid', key.name)
          params[key.name] = value
        end
      end
    end
    
    def validate
      compile_params
      @params_array.each { |(key, value)| key.run.call(params[key.name], self) if key.run }
      @args_array = @args_with_tokens.map { |(arg, val)| 
        begin
          [arg, arg.validate(val)]
        rescue
          add_error('invalid', arg.name)
          [arg, val]
        end
      }
      @args_hash = Hash[@args_array.map{|(arg, val)| [arg.name, val]}]
      
      @args = @args_array.inject([]) {|args, (arg, val)| arg.greedy? ? args.concat(val) : args.push(val); args}
      unless @tokens.empty?
        @tokens.select{|t| t.respond_to?(:name)}.each do |named_token|
          @tokens.delete(named_token)
          add_error('unrecognized', named_token.name)
        end
        
        if @errors.empty?
          @tokens.each do |token|
            add_error('unrecognized', token.lit)
          end
        end
      end
    end

    def valid?
      @errors.empty?
    end
  end
end