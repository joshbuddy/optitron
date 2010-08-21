require 'optitron'

class Runner < Optitron::CLI
  class_opt 'verbose'
  class_opt 'environment', :in => %w(production stage development test), :default => 'development'
  class_opt 'volume', :in => 1..10

  desc "Install stuff"
  opt 'force'
  def install(file, source = ".")
    puts "Installing #{file} from #{source.inspect} with params: #{params.inspect}"
  end
end

Runner.dispatch