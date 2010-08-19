class Optitron
  class Help
    def initialize(parser)
      @parser = parser
    end

    def help_line_for_opt(opt)
      opt_line = ''
      opt_line << [opt.short_name ? "-#{opt.short_name}" : nil, "--#{opt.name}"].compact.join('/')
      opt_line << "=[#{opt.type.to_s.upcase}]" unless opt.boolean?
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
      if arg.default
        arg_line << "=#{arg.default.inspect}"
      end
      arg_line << (arg.required? ? ']' : '>')
      arg_line
    end

    def generate
      cmds = {}
      @parser.commands.each do |cmd_name, cmd|
        cmd_line = "#{cmd_name}"
        cmd.args.each do |arg|
          cmd_line << " " << help_line_for_arg(arg)
        end
        cmds[cmd_line] = [cmd.desc]
        cmd.options.each do |opt|
          cmds[cmd_line] << help_line_for_opt(opt)
        end
      end
      opts_lines = @parser.options.map do |opt|
        help_line_for_opt(opt)
      end

      args_lines = @parser.args.empty? ? nil : [@parser.args.map{|arg| help_line_for_arg(arg)}.join(' '), @parser.args.map{|arg| arg.desc}.join(', ')]

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