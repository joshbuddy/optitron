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

    def inclusion_test=(tester)
      interpolate_type(tester.first)
      @inclusion_test = tester
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
      validated_type = case @type
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
      @inclusion_test.include?(validated_type) or raise if @inclusion_test
      validated_type
    end

    class Opt < Option
      attr_accessor :short_name, :run
      def initialize(name, desc = nil, opts = nil)
        if desc.is_a?(Hash)
          desc, opts = nil, desc
        end
        @name, @desc = name, desc
        @type = opts && opts[:type] || :boolean
        self.short_name = opts[:short_name] if opts && opts[:short_name]
        self.run = opts[:run] if opts && opts[:run]
        self.inclusion_test = opts[:in] if opts && opts[:in]
        self.default = opts && opts.key?(:default) ? opts[:default] : (@type == :boolean ? false : nil)
      end

      def match?(tok)
        tok.respond_to?(:name) and [name, short_name].include?(tok.name)
      end

      def find_matching_token(tokens)
        tokens.find do |t|
          if t.respond_to?(:name) and (t.name == name or t.name == short_name)
            t.respond_to?(:value) ^ (t.name == short_name)
          end
        end
      end

      def consume(response, tokens)
        if opt_tok = find_matching_token(tokens)
          opt_tok_index = tokens.index(opt_tok)
          tokens.delete_at(opt_tok_index)
          case @type
          when :boolean
            value = if opt_tok.respond_to?(:value)
              opt_tok.value
            elsif opt_tok.name == short_name and tokens[opt_tok_index].respond_to?(:lit) and BOOLEAN_VALUES.include?(tokens[opt_tok_index].lit)
              tokens.delete_at(opt_tok_index).lit
            end
            response.params_array << [self, value.nil? ? !default : value]
          when :numeric, :string
            value = if opt_tok.name == name
              if opt_tok.respond_to?(:value)
                opt_tok.value
              else
                response.add_error("missing", opt_tok.name)
              end
            elsif tokens[opt_tok_index].respond_to?(:lit)
              tokens.delete_at(opt_tok_index).lit
            elsif default
              default
            else
              response.add_error("required", opt_tok.name)
            end
            response.params_array << [self, value]
          when :array
            values = []
            values << opt_tok.value if opt_tok.respond_to?(:value)
            while tokens[opt_tok_index].respond_to?(:lit)
              values << tokens.delete_at(opt_tok_index).lit
            end
            response.params_array << [self, values]
          when :hash
            values = []
            if opt_tok.respond_to?(:value)
              response.add_error("not in the form key:value", name) if opt_tok.value[':'].nil?
              values << opt_tok.value.split(':', 2)
            end
            while tokens[opt_tok_index].respond_to?(:lit) and !tokens[opt_tok_index].lit[':'].nil?
              values << tokens.delete_at(opt_tok_index).lit.split(':', 2)
            end
            response.params_array << [self, Hash[values]]
          else
            raise "unknown type: #{@type.inspect}"
          end
        end
      end
    end
    
    class Cmd < Option
      attr_reader :options, :args, :run
      def initialize(name, desc = nil, opts = nil)
        if desc.is_a?(Hash)
          desc, opts = nil, desc
        end
        @name, @desc = name, desc
        @run = opts[:run] if opts && opts[:run]
        @options = []
        @args = []
      end
    end
    
    class Arg < Option
      attr_accessor :greedy, :inclusion_test
      alias_method :greedy?, :greedy
      def initialize(name = nil, desc = nil, opts = nil)
        if desc.is_a?(Hash)
          desc, opts = nil, desc
        end
        @name, @desc = name, desc
        self.inclusion_test = opts[:in] if opts && opts[:in]
        @required = opts && opts.key?(:required) ? opts[:required] : true
        @type = opts && opts[:type]
      end
      
      def consume(response, tokens)
        arg_tokens = tokens.select{ |tok| tok.respond_to?(:lit) }
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
