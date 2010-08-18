class Optitron
  class Tokenizer
    attr_reader :tokens
    def initialize(parser, opts)
      @parser, @opts = parser, opts
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
          when /^-(.*)/              then find_names_values($1)
          else                            Value.new(t)
          end
        }
        @tokens.flatten!
      end
    end
    
    def find_names_values(short)
      toks = []
      letters = short.split('')
      while !letters.empty?
        let = letters.shift
        toks << Named.new(let)
        if @parser.short_opts[let] && @parser.short_opts[let].type != :boolean && !letters.empty?
          toks << Value.new(letters.join)
          letters.clear
        end
      end
      toks
    end
  end
end