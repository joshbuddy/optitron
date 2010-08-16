require 'spec_helper'

describe "Optitron::Parser defaults" do
  it "should always send defaults unless you override them" do
    @parser = Optitron.new {
      opt 'ten', :default => 10
      opt 'string', :default => 'string'
      opt 'list', :default => ['one', 'two', 'three']
      opt 'hash', :default => {'hey' => 'you'}
    }
    @parser.parse([]).params.should == {"list"=>["one", "two", "three"], "hash"=>{"hey"=>"you"}, "ten"=>10, "string"=>"string"}
    @parser.parse(%w(--ten=123)).params.should == {"list"=>["one", "two", "three"], "hash"=>{"hey"=>"you"}, "ten"=>123, "string"=>"string"}
    @parser.parse(%w(--list=three two one)).params.should == {"list"=>["three", "two", "one"], "hash"=>{"hey"=>"you"}, "ten"=>10, "string"=>"string"}
  end
end