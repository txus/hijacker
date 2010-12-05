require 'spec_helper'

describe Hijacker, "configuration" do

  describe "#configure" do
    it 'evaluates the passed block' do
      block = Proc.new {}
      Hijacker.should_receive(:instance_eval).with(&block).once
      Hijacker.configure(&block) 
    end
  end

  describe "#uri" do
    it 'assigns the DRb uri as a class variable' do
      Hijacker.uri 'druby://localhost:8787'
      Hijacker.send(:class_variable_get, :@@drb_uri).should == 'druby://localhost:8787'
    end
  end

  describe "#drb_uri" do
    context "when the class variable is set" do
      it 'is an accessor to it' do
        Hijacker.send(:class_variable_set, :@@drb_uri, 'druby://localhost:8787')
        Hijacker.drb_uri.should == 'druby://localhost:8787'
      end
    end
    context "otherwise" do
      it 'raises an error' do
        Hijacker.send(:remove_class_variable, :@@drb_uri)
        expect {
          Hijacker.drb_uri
        }.to raise_error(Hijacker::UndefinedUriError)
      end
    end
  end
  
end
