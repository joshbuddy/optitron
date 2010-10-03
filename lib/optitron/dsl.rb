class Optitron
  class Dsl
    attr_reader :root

    def initialize(parser, &blk)
      @root = RootParserDsl.new(parser)
      if blk
        @root.configure_with(&blk)
        configure_options
      end
    end

    def configure_options
      @root.unclaimed_opts.each do |opt_option|
        name = opt_option.name
        if !@root.short_opts.key?(name[0].chr)
          opt_option.short_name = name[0].chr
          @root.short_opts[name[0].chr] = opt_option
        elsif !@root.short_opts.key?(name.upcase[0].chr)
          opt_option.short_name = name.upcase[0].chr
          @root.short_opts[name.upcase[0].chr] = opt_option
        end
      end
    end
    
    class AbstractDsl
      def configure_with(&block)
        instance_eval(&block)
      end
      
      def opt(name, description = nil, opts = nil)
        opt_option = Option::Opt.new(name, description, opts)
        if opt_option.short_name
          short_opts[opt_option.short_name] = opt_option
        else
          unclaimed_opts << opt_option
        end
        @target.options << opt_option
        opt_option
      end
      
      def arg(name, description = nil, opts = nil)
        arg_option = Option::Arg.new(name, description, opts)                                                                         
        raise InvalidParser.new if @target.args.last and !@target.args.last.required? and arg_option.required? and arg_option.type != :greedy
        raise InvalidParser.new if @target.args.last and @target.args.last.type == :greedy
        @target.args << arg_option
        arg_option
      end
      
      def short_opts
        @root_dsl.short_opts
      end
      
      def unclaimed_opts
        @root_dsl.unclaimed_opts
      end
    end

    class CmdParserDsl < AbstractDsl
      def initialize(root_dsl, command)
        @root_dsl = root_dsl
        @target = command
      end
      
      def opt(name, description = nil, opts = nil)
        o = super
        o.parent_cmd = @target
        o
      end

      def arg(name, description = nil, opts = nil)
        a = super
        a.parent_cmd = @target
        a
      end
    end
    
    class RootParserDsl < AbstractDsl
      attr_reader :unclaimed_opts
      def initialize(parser)
        @target = parser
        @unclaimed_opts = []
      end

      def help(desc = "Print help message")
        configure_with {
          opt 'help', desc, :short_name => '?', :suppress_no => true, :run => proc{ |value, response|
            if value
              puts @target.help
              exit(0)
            end
          }
        }
      end

      def short_opts
        @target.short_opts
      end

      def cmd(name, description = nil, opts = nil, &blk)
        command_option = Option::Cmd.new(name, description, opts)
        CmdParserDsl.new(self, command_option).configure_with(&blk) if blk
        @target.commands << [name, command_option]
      end
    end
  end
end
