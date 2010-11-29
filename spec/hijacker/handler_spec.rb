require 'spec_helper'

module Hijacker
  describe Handler do

    subject { Handler.new({:my => :option}) }

    it "initializes with options" do
      subject.opts.should == {:my => :option}
    end

    it { should respond_to(:opts)}

    it "includes DRb::DRbUndumpled" do
      Handler.included_modules.should include(DRb::DRbUndumped)
    end

    describe "#handle" do
      let(:args) do
        [:bar,
         [
          {:inspect => "2", :class => "Fixnum"},
          {:inspect => "\"string\"", :class => "String"},
         ],
         {:inspect => "\"retval\"", :class => "String"},
         nil,
         {:inspect => "MyClass", :class => "Class"}]
      end

      it "is meant to be overriden by subclasses" do
        expect {
          subject.handle(*args)
        }.to raise_error NotImplementedError
      end
    end

    describe "class methods" do
    
      describe "#register_handler" do
        context "when given a relative path" do
          it 'registers that file as a handler' do
            Hijacker::Handler.register_handler "/path/to/my/handlers/benchmark.rb"
            Hijacker::Handler.handlers.should include('benchmark')
          end
        end
        context "when given an absolute path" do
          it 'registers that file as well' do
            Hijacker::Handler.register_handler "~/.handlers/custom_handler.rb"
            Hijacker::Handler.handlers.should include('custom_handler')
          end
        end
      end

      describe "#handlers" do
        it 'is an accessor to the class variable' do
          handlers = [double('handler'),
                      double('another handler')]
          Handler.class_variable_set(:@@handlers, handlers) 
          Handler.handlers.should == handlers 
        end
      end

    end
    
  end
end
