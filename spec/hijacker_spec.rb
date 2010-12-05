require 'spec_helper'

class MyClass
  def self.foo
    3 + 4
  end
  def self.bar(a,b)
    b
  end

  def foo
    3 + 4
  end
  def bar(a,b)
    b
  end

  def baz=(value)
    @value = value
  end

  def method_that_raises
    raise StandardError, "Something went wrong"
  end

end unless defined?(MyClass)

describe Hijacker do

  describe "#register" do
    it 'sends the registered method call to the DRb server' do
      server = mock('DRb server') 

      Hijacker.stub(:drb_uri).and_return "druby://localhost:9999"

      expected_args = [:bar,
                       [
                        {:inspect => "2", :class => "Fixnum"},
                        {:inspect => "\"string\"", :class => "String"},
                       ],
                       {:inspect => "\"retval\"", :class => "String"},
                       nil,
                       {:inspect => "MyClass", :class => "Class"}
                      ]

      DRbObject.should_receive(:new).with(nil, "druby://localhost:9999").and_return server
      server.should_receive(:handle).with *expected_args

      Hijacker.register(:bar, [2, "string"], "retval", nil, MyClass) 
    end
    context "when given a particular DRb uri" do
      it "sends the call to that uri" do
        DRbObject.should_receive(:new).with(nil, "druby://localhost:1212").and_return mock('DRb server', :handle => true)
        Hijacker.register(:bar, [2, "string"], "retval", nil, MyClass, "druby://localhost:1212") 
      end
    end
  end

end
