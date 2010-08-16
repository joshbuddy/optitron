class Optitron
  class Dsl

    def initialize(parser, &blk)
      RootParserDsl.new(parser).configure_with(blk)
    end

    class AbstractDsl
      def configure_with(block)
        instance_eval(&block)
      end
      
      def opt(name, description = nil, opts = nil)
        opt_option = Option::Opt.new(name, description, opts)
        if !short_opts.include?(name[0])
          opt_option.short_name = name[0].chr
          short_opts << name[0]
        elsif !short_opts.include?(name.upcase[0])
          opt_option.short_name = name.upcase[0].chr
          short_opts << name.upcase[0]
        end
        @target.options << opt_option
      end
      
      def arg(name, description = nil, opts = nil)
        arg_option = Option::Arg.new(name, description, opts)
        raise InvalidParser.new if @target.args.last and !@target.args.last.required? and arg_option.required?
        raise InvalidParser.new if @target.args.last and @target.args.last.type == :greedy
        @target.args << arg_option
        arg_option
      end
      
      def short_opts
        @root_dsl.short_opts
      end
    end

    class CmdParserDsl < AbstractDsl
      def initialize(root_dsl, command)
        @root_dsl = root_dsl
        @target = command
      end
    end
    
    class RootParserDsl < AbstractDsl
      attr_reader :short_opts
      def initialize(parser)
        @short_opts = []
        @target = parser
      end
      
      def cmd(name, description = nil, opts = nil, &blk)
        command_option = Option::Cmd.new(name, description, opts)
        CmdParserDsl.new(self, command_option).configure_with(blk) if blk
        @target.commands[name] = command_option
      end
    end
  end
end
