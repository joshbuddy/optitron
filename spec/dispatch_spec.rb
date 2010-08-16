require 'spec_helper'

describe "Optitron::Parser dispatching" do
  it "should dispatch 'install'" do
    m = mock('mock')
    m.should_receive('install').with()
    Optitron.dispatch(m, %w(install)) {
      cmd "install"
    }
  end

  it "should dispatch 'install file'" do
    m = mock('mock')
    m.should_receive('install').with('file.rb')
    Optitron.dispatch(m, %w(install file.rb)) {
      cmd "install" do
        arg "file"
      end
    }
  end

  it "should dispatch 'install file --noop'" do
    m = mock('mock')
    m.should_receive('install').with('file.rb', {'noop' => true})
    Optitron.dispatch(m, %w(install file.rb --noop)) {
      cmd "install" do
        opt 'noop'
        arg "file"
      end
    }
  end
end