class Optitron
  class Parser
    attr_reader :commands, :options
    def initialize
      @options = []
      @commands = {}
    end

    def parse(args = ARGV)
      tokens = Tokenizer.new(args).tokens
      response = Response.new(tokens)
      options = @options 
      args = nil
      if !@commands.empty? 
        if cmd_tok = tokens.find { |t| t.is_a?(Tokenizer::Value) and @commands[t.val] }
          tokens.delete(cmd_tok)
          response.command = cmd_tok.val
          options += @commands[cmd_tok.val].options
          args = @commands[cmd_tok.val].args
        else
          response.add_error(nil, 'unknown command')
        end
      end
      parse_options(tokens, options, response)
      parse_args(tokens, args, response)
      response.validate
      response
    end

    def parse_options(tokens, options, response)
      options.each do |opt|
        if opt_tok = tokens.find { |tok| opt.match?(tok) }
          opt_tok_index = tokens.index(opt_tok)
          opt.consume(response, tokens)
        end
      end
    end
    
    def parse_args(tokens, args, response)
      args.each { |arg| arg.consume(response, tokens) } if args
    end

    def help
      cmds = {}
      @commands.each do |cmd_name, cmd|
        cmd_line = "#{cmd_name}"
        cmd.args.each do |arg|
          cmd_line << " "
          cmd_line << (arg.required? ? '[' : '<')
          if arg.type == :greedy
            cmd_line << arg.name << '1 ' << arg.name << '2 ...' 
          else
            cmd_line << arg.name
          end
          cmd_line << (arg.required? ? ']' : '>')
        end
        cmds[cmd_line] = [cmd.desc]
        cmd.options.each do |opt|
          opt_line = ''
          opt_line << [opt.short_name ? "-#{opt.short_name}" : nil, "--#{opt.name}"].compact.join('/')
          opt_line << "=[#{opt.type.to_s.upcase}]" if opt.type != :boolean
          cmds[cmd_line] << [opt_line, opt.desc]
        end
      end
      opts_lines = @options.map do |opt|
        opt_line = ''
        opt_line << [opt.short_name ? "-#{opt.short_name}" : nil, "--#{opt.name}"].compact.join('/')
        opt_line << "=[#{opt.type.to_s.upcase}]" if opt.type != :boolean
        [opt_line, opt.desc]
      end

      longest_line = cmds.keys.map{|k| k.size}.max
      opt_lines = cmds.map{|k,v| k.size + 2}.flatten
      longest_line = [longest_line, opt_lines.max].max unless opt_lines.empty?
      longest_line = [opts_lines.map{|o| o.first.size}.max, longest_line].max unless opts_lines.empty?
      help_output = "Commands\n\n" + cmds.map do |cmd, opts|
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
      unless opts_lines.empty?
        help_output << "\n\nGlobal options\n\n"
        help_output << opts_lines.map do |opt|
          opt_text = ''
          opt_text << "%-#{longest_line}s     " % opt.first
          opt_text << "# #{opt.last}" if opt.last
          opt_text
        end.join("\n")
      end
    end
  end
end