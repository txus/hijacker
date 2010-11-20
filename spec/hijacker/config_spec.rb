require 'spec_helper'

describe Hijacker, "configuration" do

  describe "#configure" do
    it 'accepts a block with the \'uri\' configuration option' do
      Hijacker.configure do
        uri 'druby://localhost:8787'
      end
      Hijacker.drb_uri.should == 'druby://localhost:8787'
    end
  end
  
end
