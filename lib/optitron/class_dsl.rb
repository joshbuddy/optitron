require 'callsite'
require 'parameters_extra'

class Optitron
  
  module ClassDsl
    
    def self.included(o)
      o.class_eval "
      attr_accessor :params
      class << self;
        include ClassMethods
      end"
    end

    module ClassMethods
      def method_added(m)
        if @last_desc
          last_opts = @opts
          @cmds ||= []
          @cmds << [m.to_s, @last_desc, @opts ? @opts.dup : []]
          @opts.clear if @opts
          @args.clear if @args
          @last_desc = nil
          @last_group = nil
        end
      end

      def optitron_parser
        send(:class_variable_set, :@@optitron_parser, Optitron::Parser.new) unless send(:class_variable_defined?, :@@optitron_parser)
        send(:class_variable_get, :@@optitron_parser)
      end
      
      def optitron_dsl
        send(:class_variable_set, :@@optitron_dsl, Optitron::Dsl.new(optitron_parser)) unless send(:class_variable_defined?, :@@optitron_dsl)
        send(:class_variable_get, :@@optitron_dsl)
      end
      
      def class_opt(name, desc = nil, opts = nil)
        optitron_dsl.root.opt(name, desc, opts)
      end

      def dont_use_help
        send(:class_variable_set, :@@suppress_help, true)
      end

      def desc(desc)
        ParametersExtra.register(Callsite.parse(caller.first).filename)
        @last_desc = desc
      end

      def group(group)
        @last_group = group
      end

      def opt(name, desc = nil, opts = nil)
        @opts ||= []
        @opts << [name, desc, opts]
      end

      def arg_types(*types)
        @arg_types = types
      end

      def build(&blk)
        unless @built
          optitron_parser.target = blk ? blk.call : new
          target = optitron_parser.target
          optitron_dsl.root.help unless send(:class_variable_defined?, :@@suppress_help)
          @cmds.each do |(cmd_name, cmd_desc, opts)|
            method = target.class.instance_method(cmd_name.to_sym).bind(target)
            arg_types = @arg_types
            optitron_dsl.root.cmd(cmd_name, cmd_desc) do
              opts.each { |o| opt *o }
              puts "!!! #{cmd_name.inspect}" if method.nil?
              method.parameters_extra.each do |arg|
                possible_arg_type = arg.name.to_s[/_(string|hash|array|numeric|int|float)$/, 1]
                arg_name = if possible_arg_type && (arg_types.nil? || !arg_types.first)
                  possible_arg_type = possible_arg_type.to_sym
                  arg.name.to_s[/^(.*)_(?:string|hash|array|numeric|int|float)$/, 1]
                else
                  arg.name
                end
                arg_opts = { :default => arg.default_value, :type => arg_types && arg_types.shift || possible_arg_type }
                case arg.type
                when :required
                  arg arg_name.to_s, arg_opts
                when :optional
                  arg arg_name.to_s, arg_opts.merge(:required => false)
                when :splat
                  arg arg_name.to_s, arg_opts.merge(:type => :greedy)
                end
              end
            end
          end
          optitron_dsl.configure_options
          @built = true
        end
      end

      def dispatch(args = ARGV, &blk)
        build(&blk)
        response = optitron_parser.parse(args)
        if response.valid?
          optitron_parser.target.params = response.params
          args = response.args
          parser_args = optitron_parser.commands.assoc(response.command).last.args
          while (args.size < parser_args.size && !(parser_args[args.size].type == :greedy && parser_args[args.size].default.nil?))
            args << parser_args[args.size].default 
          end

          optitron_parser.target.send(response.command.to_sym, *response.args)
        else
          puts optitron_parser.help

          unless response.args.empty?
            puts response.error_messages.join("\n")
          end
        end
      end
    end
  end
end
