require 'callsite'
require 'ruby2ruby'
require 'ruby_parser'
require 'sexp_processor'

class Optitron
  
  class MethodArgs < SexpProcessor
    attr_reader :method_map
    def initialize(cls)
      @cls = cls
      @method_map = {}
      super()
    end

    def process_class(exp)
      exp.shift
      @current_class = exp.first.to_sym
      process(exp)
      exp.clear
      exp
    end

    def process_defn(exp)
      exp.shift
      @current_method = exp.shift
      @ruby2ruby = Ruby2Ruby.new
      process_args(exp.shift)
      scope = exp.shift
      exp
    end

    def process_args(exp)
      exp.shift
      arg_list = []
      while !exp.empty?
        t = exp.shift
        case t
        when Symbol
          arg_list << if t.to_s[0] == ?*
            [t.to_s[1, t.to_s.size].to_sym, :greedy]
          else
            [t, :required]
          end
        when Sexp
          case t.shift
          when :block
            lasgn = t.shift
            lasgn.shift
            name = lasgn.shift
            sub_part = arg_list.find{|arg| arg.first == name}
            sub_part.clear
            sub_part << name
            sub_part << :optional
            sub_part << @ruby2ruby.process(lasgn.last)
          end
        end
      end
      @method_map[@current_method] = arg_list if @cls.name.to_sym == @current_class
    end
  end
  
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
      
      def method_args
        send(:class_variable_get, :@@method_args)
      end

      def build_method_args(file)
        unless send(:class_variable_defined?, :@@method_args)
          parser = RubyParser.new
          sexp = parser.process(File.read(file))
          method_args = MethodArgs.new(self)
          method_args.process(sexp)
          send(:class_variable_set, :@@method_args, method_args.method_map)
        end
        send(:class_variable_get, :@@method_args)
      end
      
      def class_opt(name, desc = nil, opts = nil)
        optitron_dsl.root.opt(name, desc, opts)
      end

      def dont_use_help
        send(:class_variable_set, :@@suppress_help, true)
      end

      def desc(desc)
        build_method_args(Callsite.parse(caller.first).filename)
        @last_desc = desc
      end

      def opt(name, desc = nil, opts = nil)
        @opts ||= []
        @opts << [name, desc, opts]
      end

      def build
        unless @built
          optitron_dsl.root.help unless send(:class_variable_defined?, :@@suppress_help)
          @cmds.each do |(cmd_name, cmd_desc, opts)|
            args = method_args[cmd_name.to_sym]
            arity = instance_method(cmd_name).arity
            optitron_dsl.root.cmd(cmd_name, cmd_desc) do
              opts.each { |o| opt *o }
              args.each do |(arg_name, arg_type, arg_default)|
                case arg_type
                when :required
                  arg arg_name.to_s, :default => arg_default && eval(arg_default)
                when :optional
                  arg arg_name.to_s, :default => arg_default && eval(arg_default), :required => false
                when :greedy
                  arg arg_name.to_s, :default => arg_default && eval(arg_default), :type => :greedy
                end
              end
            end
          end
          optitron_dsl.configure_options
          @built = true
        end
      end

      def dispatch(args = ARGV, &blk)
        build
        optitron_parser.target = blk ? blk.call : new
        response = optitron_parser.parse(args)
        if response.valid?
          optitron_parser.target.params = response.params
          args = response.args
          while (args.size < optitron_parser.commands.assoc(response.command).last.args.size)
            args << optitron_parser.commandsassoc(response.command).last.args[args.size].default
          end
          optitron_parser.target.send(response.command.to_sym, *response.args)
        else
          puts response.error_messages.join("\n")
        end
      end
    end
  end
end