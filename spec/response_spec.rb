require 'spec_helper'

describe "Optitron::Response" do
  context "when validation fails" do
    it "should output error messages" do
      parser = Optitron.new do
        cmd "foo" do
        end
      end

      response = parser.parse([])
      response.should_receive(:puts).with("Unknown command")
      response.dispatch(nil)
    end
  end
end