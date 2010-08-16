require 'spec_helper'

describe "Optitron::Parser options" do
  context "long names vs short names" do
    before(:each) do
      @parser = Optitron.new {
        opt "option", :type => :string
      }
    end
    
    it "should parse '-o test'" do
      @parser.parse(%w(-o test)).params.should == {'option' => 'test'}
    end

    it "should parse '--option=test'" do
      @parser.parse(%w(--option=test)).params.should == {'option' => 'test'}
    end

    it "shouldn't parse '--option test'" do
      @parser.parse(%w(--option test)).valid?.should be_false
    end

    it "shouldn't parse '-option test'" do
      @parser.parse(%w(-option test)).valid?.should be_false
    end
  end

  context "boolean long names vs short names" do
    before(:each) do
      @parser = Optitron.new {
        opt "verbose"
      }
    end
    
    it "should parse '-v true'" do
      @parser.parse(%w(-v true)).valid?.should be_true
    end

    it "shouldn't parse '-v that'" do
      @parser.parse(%w(-v that)).valid?.should be_false
    end

    it "shouldn't parse '--verbose true'" do
      @parser.parse(%w(--verbose true)).valid?.should be_false
    end

    it "shouldn't parse '--verbose=true'" do
      @parser.parse(%w(--verbose=true)).valid?.should be_true
    end
  end

  context "multiple options" do
    before(:each) do
      @parser = Optitron.new {
        opt "1"
        opt "2"
        opt "3"
        opt "option", :type => :string
      }
    end
    
    it "should parse '-123o test'" do
      @parser.parse(%w(-123o test)).params.should == {'option' => 'test', '1' => true, '2' => true, '3' => true}
    end
  end
end