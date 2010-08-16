class Optitron
  class Parser
    attr_accessor :target
    attr_reader :commands, :options, :args
    def initialize
      @options = []
      @commands = {}
      @args = []
    end

    def parse(args = ARGV)
      tokens = Tokenizer.new(args).tokens
      response = Response.new(self, tokens)
      options = @options 
      args = @args
      if !@commands.empty?
        potential_cmd_toks = tokens.select { |t| t.respond_to?(:val) }
        if cmd_tok = potential_cmd_toks.find { |t| @commands[t.val] }
          tokens.delete(cmd_tok)
          response.command = cmd_tok.val
          options += @commands[cmd_tok.val].options
          args = @commands[cmd_tok.val].args
        else
          potential_cmd_toks.first ?
            response.add_error('an unknown command', potential_cmd_toks.first.val) :
            response.add_error('unknown command')
        end
      end
      parse_options(tokens, options, response)
      parse_args(tokens, args, response)
      response.validate
      response
    end

    def parse_options(tokens, options, response)
      options.each do |opt|
        response.params[opt.name] = opt.default if opt.has_default?
        if opt_tok = tokens.find { |tok| opt.match?(tok) }
          opt_tok_index = tokens.index(opt_tok)
          opt.consume(response, tokens)
        end
      end
    end
    
    def parse_args(tokens, args, response)
      args.each { |arg| arg.consume(response, tokens) } if args
    end

    def help_line_for_opt(opt)
      opt_line = ''
      opt_line << [opt.short_name ? "-#{opt.short_name}" : nil, "--#{opt.name}"].compact.join('/')
      opt_line << "=[#{opt.type.to_s.upcase}]" if opt.type != :boolean
      [opt_line, opt.desc]
    end

    def help_line_for_arg(arg)
      arg_line = ''
      arg_line << (arg.required? ? '[' : '<')
      if arg.type == :greedy
        arg_line << arg.name << '1 ' << arg.name << '2 ...' 
      else
        arg_line << arg.name
      end
      arg_line << (arg.required? ? ']' : '>')
      arg_line
    end

    def help
      cmds = {}
      @commands.each do |cmd_name, cmd|
        cmd_line = "#{cmd_name}"
        cmd.args.each do |arg|
          cmd_line << " " << help_line_for_arg(arg)
        end
        cmds[cmd_line] = [cmd.desc]
        cmd.options.each do |opt|
          cmds[cmd_line] << help_line_for_opt(opt)
        end
      end
      opts_lines = @options.map do |opt|
        help_line_for_opt(opt)
      end

      args_lines = args.empty? ? nil : [args.map{|arg| help_line_for_arg(arg)}.join(' '), args.map{|arg| arg.desc}.join(', ')]

      longest_line = 0
      longest_line = [longest_line, cmds.keys.map{|k| k.size}.max].max unless cmds.empty?
      opt_lines = cmds.map{|k,v| k.size + 2}.flatten
      longest_line = [longest_line, args_lines.first.size].max if args_lines
      longest_line = [longest_line, opt_lines.max].max unless opt_lines.empty?
      longest_line = [opts_lines.map{|o| o.first.size}.max, longest_line].max unless opts_lines.empty?
      help_output = []

      unless cmds.empty?
        help_output << "Commands\n\n" + cmds.map do |cmd, opts|
          cmd_text = ""
          cmd_text << "%-#{longest_line}s     " % cmd
          cmd_desc = opts.shift
          cmd_text << "# #{cmd_desc}" if cmd_desc
          opts.each do |opt|
            cmd_text << "\n  %-#{longest_line}s   " % opt.first
            cmd_text << "# #{opt.last}" if opt.last
          end
          cmd_text
        end.join("\n")
      end
      if args_lines
        arg_help = "Arguments\n\n"
        arg_help << "%-#{longest_line}s     " % args_lines.first
        arg_help << "# #{args_lines.last}" if args_lines.first
        help_output << arg_help
      end
      unless opts_lines.empty?
        help_output << "Global options\n\n" + opts_lines.map do |opt|
          opt_text = ''
          opt_text << "%-#{longest_line}s     " % opt.first
          opt_text << "# #{opt.last}" if opt.last
          opt_text
        end.join("\n")
      end
      help_output.join("\n\n")
    end
  end
end