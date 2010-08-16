require 'spec_helper'

describe "Optitron::Parser" do
  context "A simple command" do
    before(:each) {
      @parser = Optitron.new {
        cmd "start"
        cmd "stop"
      }
    }

    it "should parse 'start'" do
      response = @parser.parse(%w(start))
      response.command.should == 'start'
      response.valid?.should be_true
    end

    it "should parse 'stop'" do
      response = @parser.parse(%w(stop))
      response.command.should == 'stop'
      response.valid?.should be_true
    end

    it "shouldn't parse 'restart'" do
      response = @parser.parse(%w(restart))
      response.command.should be_nil
      response.valid?.should be_false
    end
  end

  context "A simple command with a switch" do
    before(:each) {
      @parser = Optitron.new {
        opt "verbose"
        cmd "start"
        cmd "stop"
      }
    }

    it "should parse 'start --verbose'"  do
      response = @parser.parse(%w(start --verbose))
      response.command.should == 'start'
      response.params['verbose'].should be_true
      response.valid?.should be_true
    end

    it "should parse 'start --verbose=false'"  do
      response = @parser.parse(%w(start --verbose=false))
      response.command.should == 'start'
      response.params['verbose'].should be_false
      response.valid?.should be_true
    end

    it "should parse '--verbose start'"  do
      response = @parser.parse(%w(--verbose start))
      response.command.should == 'start'
      response.params['verbose'].should be_true
      response.valid?.should be_true
    end

    it "should parse '-v start'"  do
      response = @parser.parse(%w(-v start))
      response.command.should == 'start'
      response.params['verbose'].should be_true
      response.valid?.should be_true
    end

    it "should parse 'start -v'"  do
      response = @parser.parse(%w(start -v))
      response.command.should == 'start'
      response.params['verbose'].should be_true
      response.valid?.should be_true
    end
  end

  context "A simple command with an arg" do
    before(:each) {
      @parser = Optitron.new {
        cmd "start" do
          arg "name"
        end
      }
    }

    it "should parse 'start love'"  do
      response = @parser.parse(%w(start love))
      response.command.should == 'start'
      response.args.first.should == 'love'
      response.valid?.should be_true
    end

    it "shouldn't parse 'start'"  do
      response = @parser.parse(%w(start))
      response.command.should == 'start'
      response.valid?.should be_false
    end
  end
end