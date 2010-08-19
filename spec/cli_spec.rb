require 'spec_helper'

class CLIExample < Optitron::CLI
  class_opt 'verbose'
  use_help

  def a_method_we_didnt_describe
  end

  desc "Use this"
  opt 'use_opt'
  def use
    puts "using this"
  end

  desc "Use this too"
  opt 'another_opt'
  def use_too(one, two = 'three')
  end

  desc "Use this three"
  opt 'another_opt_as_well', :default => 123
  def use_greedy(one, *two)
  end
end


describe "Optitron::Parser defaults" do
  it "should generate the correct help" do
    CLIExample.build
    CLIExample.optitron_parser.help.strip.should == "Commands\n\nuse_greedy [one] [two1 two2 ...]       # Use this three\n  -A/--another_opt_as_well=[NUMERIC]   \nuse_too [one] <required=\"three\">       # Use this too\n  -a/--another_opt                     \nuse                                    # Use this\n  -u/--use_opt                         \n\nGlobal options\n\n-v/--verbose                           \n-?/--help                              # Print help message"
  end

  it "should dispatch" do
    capture(:stdout) { CLIExample.dispatch(%w(use))}.should == "using this\n"
  end
end