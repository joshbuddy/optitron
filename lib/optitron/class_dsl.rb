class Optitron
  module ClassDsl
    
    def self.included(o)
      o.module_eval "
      @@optitron_parser = Optitron::Parser.new
      @@optitron_dsl = Optitron::Dsl.new(@@optitron_parser)
      attr_accessor :params
      class << self;
        include ClassMethods
      end"
    end


    module ClassMethods
      def method_added(m)
        last_opts = @opts
        @cmds ||= []
        @cmds << [m.to_s, @last_desc, @args.dup || [], @opts.dup || []]
        @opts.clear if @opts
        @args.clear if @args
      end

      def optitron_dsl
        self.send(:class_variable_get, :@@optitron_dsl)
      end
      
      def optitron_parser
        self.send(:class_variable_get, :@@optitron_parser)
      end
      
      def class_opt(name, desc = nil, opts = nil)
        optitron_dsl.root.opt(name, desc, opts)
      end

      def use_help
        optitron_dsl.root.help
      end

      def desc(desc)
        @last_desc = desc
      end

      def arg(name, desc = nil, opts = nil)
        @args ||= []
        @args << [name, desc, opts]
      end

      def opt(name, desc = nil, opts = nil)
        @opts ||= []
        @opts << [name, desc, opts]
      end

      def build
        @cmds.each do |(cmd_name, cmd_desc, args, opts)|
          arity = instance_method(cmd_name).arity
          optitron_dsl.root.cmd(cmd_name, cmd_desc) do
            opts.each { |o| opt *o }
            args.each { |a| arg *a }
          end
        end
        optitron_dsl.configure_options
      end

      def dispatch
        build
        optitron_parser.target = new
        response = optitron_parser.parse(ARGV)
        if response.valid?
          optitron_parser.target.params = response.params
          args = response.args
          while (args.size < optitron_parser.commands[response.command].args.size)
            args << optitron_parser.commands[response.command].args[args.size].default
          end
          optitron_parser.target.send(response.command.to_sym, *response.args)
        else
          puts response.error_messages.join("\n")
        end
      end
    end
  end
end