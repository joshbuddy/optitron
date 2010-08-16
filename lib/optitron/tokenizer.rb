class Optitron
  class Tokenizer
    attr_reader :tokens
    def initialize(opts)
      @opts = opts
      tokenize
    end

    Value = Struct.new(:val)
    Named = Struct.new(:name)
    NamedWithValue = Struct.new(:name, :value)

    def tokenize
      unless @tokens
        @tokens = @opts.map {|t|
          case t
          when /^--([^=]+)=([^=]+)$/ then NamedWithValue.new($1, $2)
          when /^--([^=]+)$/         then Named.new($1)
          when /^-(.*)/              then $1.split('').map{|letter| Named.new(letter)}
          else                          Value.new(t)
          end
        }
        @tokens.flatten!
      end
    end
  end
end