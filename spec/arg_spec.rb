require 'spec_helper'

describe "Optitron::Parser arg spec" do
  context "one requied arg" do
    before(:each) {
      @parser = Optitron.new {
        cmd "install" do
          arg "file"
        end
      }
    }

    it "should parse 'install life.rb'" do
      response = @parser.parse(%w(install life.rb))
      response.command.should == 'install'
      response.args.should == ['life.rb']
      response.valid?.should be_true
    end

    it "shouldn't parse 'install'" do
      response = @parser.parse(%w(install))
      response.command.should == 'install'
      response.valid?.should be_false
    end

    it "shouldn't parse 'install life.rb life.rb'" do
      response = @parser.parse(%w(install life.rb life.rb))
      response.command.should == 'install'
      response.valid?.should be_false
    end
  end

  context "one optional arg" do
    before(:each) {
      @parser = Optitron.new {
        cmd "install" do
          arg "file", :required => false
        end
      }
    }

    it "should parse 'install life.rb'" do
      response = @parser.parse(%w(install life.rb))
      response.command.should == 'install'
      response.args.should == ['life.rb']
      response.valid?.should be_true
    end

    it "should parse 'install'" do
      response = @parser.parse(%w(install))
      response.command.should == 'install'
      response.valid?.should be_true
    end

    it "shouldn't parse 'install life.rb life.rb'" do
      response = @parser.parse(%w(install life.rb life.rb))
      response.command.should == 'install'
      response.valid?.should be_false
    end
  end

  context "one requied arg & one optional arg" do
    before(:each) {
      @parser = Optitron.new {
        cmd "install" do
          arg "file"
          arg "file2", :required => false
        end
      }
    }

    it "should parse 'install life.rb'" do
      response = @parser.parse(%w(install life.rb))
      response.command.should == 'install'
      response.args.should == ['life.rb']
      response.valid?.should be_true
    end

    it "shouldn't parse 'install'" do
      response = @parser.parse(%w(install))
      response.command.should == 'install'
      response.valid?.should be_false
    end

    it "should parse 'install life.rb life.rb'" do
      response = @parser.parse(%w(install life.rb life.rb))
      response.command.should == 'install'
      response.args.should == ['life.rb', 'life.rb']
      response.valid?.should be_true
    end
  end

  context "one required greedy arg" do
    before(:each) {
      @parser = Optitron.new {
        cmd "install" do
          arg "files", :type => :greedy, :required => true
        end
      }
    }

    it "should parse 'install life.rb'" do
      response = @parser.parse(%w(install life.rb))
      response.command.should == 'install'
      response.args.should == ['life.rb']
      response.valid?.should be_true
    end

    it "shouldn't parse 'install'" do
      response = @parser.parse(%w(install))
      response.command.should == 'install'
      response.valid?.should be_false
    end

    it "should parse 'install life.rb life.rb'" do
      response = @parser.parse(%w(install life.rb life.rb))
      response.command.should == 'install'
      response.args.should == ['life.rb', 'life.rb']
      response.valid?.should be_true
    end
  end

  context "one optional + one greedy arg" do
    before(:each) {
      @parser = Optitron.new {
        cmd "install" do
          arg "values", :default => [1,2,3]
          arg "files", :type => :greedy
        end
      }
    }

    it "should parse 'install'" do
      response = @parser.parse(%w(install))
      response.command.should == 'install'
      response.args.should == [[1,2,3]]
      response.valid?.should be_true
    end

  end

  context "invalid parsers" do
    it "shouldn't allow a required arg after an optional arg" do
      proc {
        Optitron.new {
          cmd "install" do
            arg "file", :required => false
            arg "file2", :required => true
          end
        }
      }.should raise_error(Optitron::InvalidParser)
    end

    it "shouldn't allow an arg after a greedy arg" do
      proc {
        Optitron.new {
          cmd "install" do
            arg "file", :type => :greedy
            arg "file2"
          end
        }
      }.should raise_error(Optitron::InvalidParser)
    end
  end
  
  context "root level args" do
    before(:each) {
      @parser = Optitron.new {
        arg "file"
      }
    }

    it "should parse" do
      response = @parser.parse(%w(life.rb))
      response.command.should be_nil
      response.args.should == ['life.rb']
      response.valid?.should be_true
    end
  end
end