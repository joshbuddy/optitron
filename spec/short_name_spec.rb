require 'spec_helper'

describe "Optitron::Parser short_name generation" do
  context "Two conflicting short names" do
    before(:each) {
      @parser = Optitron.new {
        opt "something"
        opt "something-else"
      }
    }

    it "should parse '--something --something-else'" do
      response = @parser.parse(%w(--something --something-else))
      response.params.should == {'something' => true, 'something-else' => true}
      response.valid?.should be_true
    end

    it "should parse '-s -S'" do
      response = @parser.parse(%w(-s -S))
      response.params.should == {'something' => true, 'something-else' => true}
      response.valid?.should be_true
    end

    it "should parse '-s'" do
      response = @parser.parse(%w(-s))
      response.params.should == {'something' => true}
      response.valid?.should be_true
    end

    it "should parse '-S'" do
      response = @parser.parse(%w(-S))
      response.params.should == {'something-else' => true}
      response.valid?.should be_true
    end
  end
end