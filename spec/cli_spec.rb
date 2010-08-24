require 'spec_helper'

class CLIExample < Optitron::CLI

  def a_method_we_didnt_describe
  end

  class_opt 'verbose'

  desc "Use this"
  opt 'use_opt'
  def use
    puts "using this"
  end

  desc "Use this too"
  opt 'another_opt'
  arg_types :hash
  def use_too(one, two = 'three')
    puts "one: #{one.to_a.sort.inspect} #{two.inspect}"
  end

  desc "Use this three"
  opt 'another_opt_as_well', :default => 123
  def use_greedy(one, *two)
  end

  desc "something with an array"
  def with_array(ary=[1,2,3])
  end
end

class AnotherCLIExample < Optitron::CLI

  def initialize(env)
    @env = env
  end

  class_opt 'verbose'

  desc "Use this too"
  opt 'another_opt'
  def use_too(one, two = 'three')
    puts "using this too #{one} #{two} #{params['another_opt']} #{@env}"
  end
end

class NoHelpExample < Optitron::CLI

  dont_use_help

  class_opt 'verbose'

  desc "Use this too"
  opt 'another_opt'
  def use_too(one, two = 'three')
    puts "using this too #{one} #{two} #{params['another_opt']} #{@env}"
  end
end

class CLIExampleWithArgHinting < Optitron::CLI
  desc "Use this too"
  def use_too(one_string, two_int)
    puts "using this too #{one_string.inspect} #{two_int.inspect}"
  end
end


describe "Optitron::Parser defaults" do
  it "should generate the correct help" do
    CLIExample.build
    CLIExample.optitron_parser.help.strip.should == "Commands\n\nuse                                    # Use this\n  -u/--use_opt                         \nuse_too [one] <two=\"three\">            # Use this too\n  -a/--another_opt                     \nuse_greedy [one] <two1 two2 ...>       # Use this three\n  -A/--another_opt_as_well=[NUMERIC]   \nwith_array <ary=[1, 2, 3]>             # something with an array\n\nGlobal options\n\n-v/--verbose                           \n-?/--help                              # Print help message"
  end

  it "should dispatch" do
    capture(:stdout) { CLIExample.dispatch(%w(use))}.should == "using this\n"
  end

  it "should dispatch with the type hinting" do
    capture(:stdout) { CLIExample.dispatch(%w(use_too one:two three:four))}.should == 'one: [["one", "two"], ["three", "four"]] "three"' + "\n"
  end

  it "should generate the correct help" do
    AnotherCLIExample.build
    AnotherCLIExample.optitron_parser.help.strip.should == "Commands\n\nuse_too [one] <two=\"three\">       # Use this too\n  -a/--another_opt                \n\nGlobal options\n\n-v/--verbose                      \n-?/--help                         # Print help message"
  end

  it "should dispatch with a custom initer" do
    capture(:stdout) { AnotherCLIExample.dispatch(%w(use_too three four --another_opt)) { AnotherCLIExample.new("test") }  }.should == "using this too three four true test\n"
  end

  it "should be able to suppress help" do
    capture(:stdout) { NoHelpExample.dispatch(%w(--help)) }.should == "Unknown command\nHelp is unrecognized\n"
  end

  it "should get type hinting from arg names" do
    capture(:stdout) { CLIExampleWithArgHinting.dispatch(%w(use_too asd 123)) }.should == "using this too \"asd\" 123\n"
  end
end