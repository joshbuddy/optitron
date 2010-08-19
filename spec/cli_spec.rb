require 'spec_helper'

class CLIExample < Optitron::CLI
  class_opt 'verbose'
  use_help

  def a_method_we_didnt_describe
  end

  desc "Use this"
  class_opt 'use_opt'
  def use
  end

  desc "Use this too"
  class_opt 'another_opt'
  def use_too(one, two = 'three')
  end

  desc "Use this three"
  class_opt 'another_opt_as_well', :default => 123
  def use_greedy(one, *two)
  end
end


describe "Optitron::Parser defaults" do
  it "should always send defaults unless you override them" do
    CLIExample.optitron_parser.help.strip.should == "Global options\n\n--verbose                           \n-?/--help                           # Print help message\n--use_opt                           \n--another_opt                       \n--another_opt_as_well=[NUMERIC]"
  end
end