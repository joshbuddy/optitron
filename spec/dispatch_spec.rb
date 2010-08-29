require 'spec_helper'

describe "Optitron::Response dispatch" do
  it "should dispatch" do
    target = mock('target')
    target.should_receive(:params=).with({'verbose' => false})
    target.should_receive(:install).with('thefile')
    @parser = Optitron.new {
      opt 'verbose', "Be very loud"
      cmd "install", "This installs things" do
        arg "file", "The file to install"
      end
    }
    @parser.parse(%w(install thefile)).dispatch(target)
  end
end