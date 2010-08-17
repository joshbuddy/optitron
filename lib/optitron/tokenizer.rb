class Optitron
  class Tokenizer
    attr_reader :tokens
    def initialize(opts)
      @opts = opts
      tokenize
    end

    Value = Struct.new(:lit)
    Named = Struct.new(:name)
    NamedWithValue = Struct.new(:name, :value)

    def tokenize
      unless @tokens
        @tokens = @opts.map {|t|
          case t
          when /^--([^=]+)=([^=]+)$/ then NamedWithValue.new($1, $2)
          when /^--([^=]+)$/         then NamedWithValue.new($1, nil)
          when /^-(.*)/              then $1.split('').map{|letter| Named.new(letter)}
          else                            Value.new(t)
          end
        }
        @tokens.flatten!
      end
    end
  end
end