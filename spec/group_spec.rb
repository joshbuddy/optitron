require 'spec_helper'

describe "Optitron::Parser groups" do
  it "generate help for command parsers" do
    @parser = Optitron.new {
      opt 'verbose', "Be very loud", :use_no => true
      cmd "install", "This installs things", :group => "group1" do
        arg "file", "The file to install"
      end
      cmd "show", "This shows things", :group => "group1" do
        arg "first", "The first thing to show"
        arg "second", "The second optional thing to show", :required => false
      end
      cmd "kill", "This kills things", :group => "group2" do
        opt "pids", "A list of pids to kill", :type => :array
        opt "pid", "A pid to kill", :type => :numeric
        opt "names", "Some sort of hash", :type => :hash
      end
      cmd "join", "This joins things" do
        arg "thing", "Stuff to join", :type => :greedy, :required => true
      end
    }
    @parser.help.should == "Commands\n\njoin [thing1 thing2 ...]       # This joins things\n                               #   thing -- Stuff to join\ngroup1:\nshow [first] <second>          # This shows things\n                               #   first -- The first thing to show\n                               #   second -- The second optional thing to show\ninstall [file]                 # This installs things\n                               #   file -- The file to install\ngroup2:\nkill                           # This kills things\n  -p/--pids=[ARRAY]            # A list of pids to kill\n  -P/--pid=[NUMERIC]           # A pid to kill\n  -n/--names=[HASH]            # Some sort of hash\n\nGlobal options\n\n-v/--(no-)verbose              # Be very loud"
  end
end