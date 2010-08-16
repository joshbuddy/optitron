require 'spec_helper'

describe "Optitron::Parser dispatching" do
  it "should dispatch 'install'" do
    m = mock('mock')
    m.should_receive('install').with()
    @parser = Optitron.new {
      cmd "install"
    }
    @parser.parse(%w(install)).dispatch(m)
  end

  it "should dispatch 'install file'" do
    m = mock('mock')
    m.should_receive('install').with('file.rb')
    @parser = Optitron.new {
      cmd "install" do
        arg "file"
      end
    }
    @parser.parse(%w(install file.rb)).dispatch(m)
  end

  it "should dispatch 'install file --noop'" do
    m = mock('mock')
    m.should_receive('install').with('file.rb', {'noop' => true})
    @parser = Optitron.new {
      cmd "install" do
        opt 'noop'
        arg "file"
      end
    }
    @parser.parse(%w(install file.rb --noop)).dispatch(m)
  end
end