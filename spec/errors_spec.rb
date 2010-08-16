require 'spec_helper'

describe "Optitron::Parser errors" do
  it "should fail on invalid commands" do
    @parser = Optitron.new {
      cmd "command"
    }
    response = @parser.parse(%w[])
    response.valid?.should be_false
    response.error_messages.should == ["Unknown command"]
  end

  it "should fail on missing args" do
    @parser = Optitron.new {
      cmd "command" do
        arg "argument"
      end
    }
    response = @parser.parse(%w[command])
    response.valid?.should be_false
    response.error_messages.should == ["Argument is required"]
  end

  it "should fail on invalid opts" do
    @parser = Optitron.new {
      cmd "command" do
        opt "option", :type => :numeric
      end
    }
    response = @parser.parse(%w[command --option=asd])
    response.valid?.should be_false
    response.error_messages.should == ["Option is invalid"]
  end

  it "should fail on extra args" do
    @parser = Optitron.new {
      cmd "command" do
        arg "argument"
      end
    }
    response = @parser.parse(%w[command argument extra-argument])
    response.valid?.should be_false
    response.error_messages.should == ["Extra-argument is unrecognized"]
  end

  it "should fail on unrecognized options" do
    @parser = Optitron.new {
      cmd "command"
    }
    response = @parser.parse(%w[command --option])
    response.valid?.should be_false
    response.error_messages.should == ["Option is unrecognized"]
  end
end