require 'spec_helper'

module Hijacker
  describe Handler do

    subject { Handler.new({:my => :option}) }

    it "initializes with options" do
      subject.opts.should == {:my => :option}
    end

    describe "#handle" do

      let(:args) do
        [:bar,
         [
          {:inspect => "2", :class => "Fixnum"},
          {:inspect => "\"string\"", :class => "String"},
         ],
         {:inspect => "\"retval\"", :class => "String"},
         {:inspect => "MyClass", :class => "Class"}]
      end

      it "is meant to be overriden by subclasses" do
        expect {
          subject.handle(*args)
        }.to raise_error NotImplementedError
      end
    end
    
  end
end
