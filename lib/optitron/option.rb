class Optitron
  class Option
    attr_accessor :required, :name, :default, :parameterize, :type, :desc, :has_default
    alias_method :required?, :required
    alias_method :has_default?, :has_default
    alias_method :parameterize?, :parameterize

    TRUE_BOOLEAN_VALUES = [true, 't', 'T', 'true', 'TRUE']
    FALSE_BOOLEAN_VALUES = [false, 'f', 'F', 'false', 'FALSE']
    BOOLEAN_VALUES = TRUE_BOOLEAN_VALUES + FALSE_BOOLEAN_VALUES

    def default=(default)
      @has_default = true unless default.nil?
      interpolate_type(default)
      @default = default
    end
    
    def interpolate_type(default)
      @type = case default
      when nil
        @type
      when false, true
        :boolean
      when Numeric
        :numeric
      when Array
        :array
      when Hash
        :hash
      end
    end

    def validate(val)
      case @type
      when :boolean
        if TRUE_BOOLEAN_VALUES.include?(val)
          true
        elsif FALSE_BOOLEAN_VALUES.include?(val)
          false
        else
          raise
        end
      when :numeric
        Integer(val)
      when :array
        Array(val)
      when :hash
        val.is_a?(Hash) ? val : raise
      when :greedy, nil, :string
        val
      else
        raise
      end
    end

    class Opt < Option
      attr_accessor :short_name
      def initialize(name, desc = nil, opts = nil)
        if desc.is_a?(Hash)
          desc, opts = nil, desc
        end
        @name, @desc = name, desc
        @type = opts && opts[:type] || :boolean
        self.default = opts && opts.key?(:default) ? opts[:default] : (@type == :boolean ? false : nil)
      end

      def match?(tok)
        tok.respond_to?(:name) and [name, short_name].include?(tok.name)
      end

      def consume(response, tokens)
        if opt_tok = tokens.find{|t| t.respond_to?(:name) and (t.name == short_name or t.name == name)}
          opt_tok_index = tokens.index(opt_tok)
          tokens.delete_at(opt_tok_index)
          case @type
          when :boolean
            value = if opt_tok.respond_to?(:value)
              opt_tok.value
            elsif opt_tok.name == name and tokens[opt_tok_index].respond_to?(:val) and BOOLEAN_VALUES.include?(tokens[opt_tok_index].val)
              tokens.delete_at(opt_tok_index).val
            end
            response.params_array << [self, value.nil? ? !default : value]
          when :numeric
            value = if opt_tok.name == name and opt_tok.respond_to?(:value)
              opt_tok.value
            elsif tokens[opt_tok_index].respond_to?(:val)
              tokens.delete_at(opt_tok_index).val
            elsif default
              default
            else
              response.add_error("required", opt.name)
            end
            response.params_array << [self, value]
          when :array
            values = []
            values << opt_tok.value if opt_tok.respond_to?(:value)
            while tokens[opt_tok_index].respond_to?(:val)
              values << tokens.delete_at(opt_tok_index).val
            end
            response.params_array << [self, values]
          when :hash
            values = []
            if opt_tok.respond_to?(:value)
              response.add_error("not in the form key:value", name) if opt_tok.value[':'].nil?
              values << opt_tok.value.split(':', 2)
            end
            while tokens[opt_tok_index].respond_to?(:val) and !tokens[opt_tok_index].val[':'].nil?
              values << tokens.delete_at(opt_tok_index).val.split(':', 2)
            end
            response.params_array << [self, Hash[values]]
          else
            raise "unknown type: #{@type.inspect}"
          end
        end
      end
    end
    
    class Cmd < Option
      attr_reader :options, :args
      def initialize(name, desc = nil, opts = nil)
        if desc.is_a?(Hash)
          desc, opts = nil, desc
        end
        @name, @desc = name, desc
        @options = []
        @args = []
      end
    end
    
    class Arg < Option
      attr_accessor :greedy
      alias_method :greedy?, :greedy
      def initialize(name = nil, desc = nil, opts = nil)
        if desc.is_a?(Hash)
          desc, opts = nil, desc
        end
        @name, @desc = name, desc
        @required = opts && opts.key?(:required) ? opts[:required] : true
        @type = opts && opts[:type]
      end
      
      def consume(response, tokens)
        arg_tokens = tokens.select{ |tok| tok.respond_to?(:val) }
        if type == :greedy
          response.args_with_tokens << [self, []]
          while !arg_tokens.size.zero?
            arg_tok = arg_tokens.shift
            tokens.delete_at(tokens.index(arg_tok))
            response.args_with_tokens.last.last << arg_tok
          end
          if required? and response.args_with_tokens.last.last.size.zero?
            response.add_error("required", name)
          end
        else
          if arg_tokens.size.zero? and required?
            response.add_error("required", name)
          elsif !arg_tokens.size.zero?
            arg_tok = arg_tokens.shift
            tokens.delete_at(tokens.index(arg_tok))
            response.args_with_tokens << [self, arg_tok]
          end
        end
      end
    end
  end
end
