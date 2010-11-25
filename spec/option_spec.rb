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

    it "should parse '--option=\"test -testing\"'" do
      @parser.parse(['--option=test -testing']).params.should == {'option' => 'test -testing'}
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
        opt "verbose", :use_no => true
      }
    end
    
    it "should parse '-v true'" do
      @parser.parse(%w(-v true)).valid?.should be_true
    end

    it "should parse '--no-verbose'" do
      @parser.parse(%w(--no-verbose)).valid?.should be_true
      @parser.parse(%w(--no-verbose)).params['verbose'].should be_false
    end

    it "shouldn't parse '-v that'" do
      @parser.parse(%w(-v that)).valid?.should be_false
    end

    it "shouldn't parse '--verbose true'" do
      @parser.parse(%w(--verbose true)).valid?.should be_false
    end

    it "shouldn't parse '--v'" do
      @parser.parse(%w(--v)).valid?.should be_false
    end

    it "shouldn't parse '--verbose=true'" do
      @parser.parse(%w(--verbose=true)).valid?.should be_true
    end
  end

  context "auto assingment of short names" do
    before(:each) do
      @parser = Optitron.new {
        opt "verbose", :short_name => 'v'
        opt "vicious", :type => :string
        opt "vendetta", :short_name => 'V'
      }
    end
    
    it "should parse '-Vv --vicious=what'" do
      response = @parser.parse(%w(-Vv --vicious=what))
      response.valid?.should be_true
      response.params.should == {"vicious"=>"what", "vendetta"=>true, "verbose"=>true}
    end
  end

  context "auto assingment of short names in cmd parsers" do
    before(:each) do
      @parser = Optitron.new {
        cmd "one" do
          opt "verbose"
        end
        cmd "two" do
          opt "verbose"
        end
      }
    end
    
    it "should parse 'one -v'" do
      response = @parser.parse(%w(one -v))
      response.valid?.should be_true
      response.params.should == {'verbose' => true}
    end

    it "should parse 'two -V'" do
      response = @parser.parse(%w(two -V))
      response.valid?.should be_true
      response.params.should == {'verbose' => true}
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
    
    it "should parse '-123otest'" do
      @parser.parse(%w(-123otest)).params.should == {'option' => 'test', '1' => true, '2' => true, '3' => true}
    end

    it "should parse '-123o test'" do
      @parser.parse(%w(-123o test)).params.should == {'option' => 'test', '1' => true, '2' => true, '3' => true}
    end
  end

  context "required options" do
    before(:each) do
      @parser = Optitron.new {
        cmd "install" do
          opt "environment", :type => :string, :required => true
        end
      }
    end
    
    it "shouldn't parse 'install'" do
      @parser.parse(%w(install)).valid?.should be_false
    end

    it "should parse 'install -esomething'" do
      response = @parser.parse(%w(install -esomething))
      response.valid?.should be_true
      response.params.should == {'environment' => 'something'}
    end
  end

  context "array options with a comment" do
    before(:each) do
      @parser = Optitron.new {
        cmd "install" do
          opt "things", :type => :array
        end
      }
    end
    
    it "should parse '--things=one two three install'" do
      response = @parser.parse(%w(--things=one two three install))
      response.valid?.should be_true
      response.params.should == {'things' => ['one', 'two', 'three']}
    end
  end

end