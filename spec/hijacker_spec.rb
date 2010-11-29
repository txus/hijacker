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

  def foo=(value)
    @value = value
  end

  def nasty
    raise "Buuh"
  end

end

describe Hijacker do

  describe "#spying" do
    it 'runs a block spying on a particular object' do
      blk = lambda {
        MyClass.foo
      }
      Hijacker.should_receive(:spy).with(MyClass).once.ordered
      MyClass.should_receive(:foo).once.ordered
      Hijacker.should_receive(:restore).with(MyClass).once.ordered

      Hijacker.spying(MyClass, &blk)
    end

    it 'raises if no block given' do
      expect {
        Hijacker.spying(MyClass)
      }.to raise_error("No block given")
    end
  end

  describe "#spy - #restore" do

    describe "hijacking a Class" do
      describe "instance methods" do
        before(:each) do
          Hijacker.spy(MyClass, :only => :instance_methods)
        end
        it "registers method calls without arguments" do
          Hijacker.should_receive(:register).with(:foo, [], 7, nil, kind_of(MyClass), nil).ordered
          MyClass.new.foo.should == 7
        end
        it "registers method calls with arguments" do
          Hijacker.should_receive(:register).with(:bar, [2, "string"], "string", nil, kind_of(MyClass), nil).ordered
          MyClass.new.bar(2, "string").should == "string"
        end
        after(:each) do
          Hijacker.restore(MyClass)
        end
      end
      describe "class methods" do
        before(:each) do
          Hijacker.spy(MyClass)
        end
        it "registers method calls without arguments" do
          Hijacker.should_receive(:register).with(:foo, [], 7, nil, kind_of(Class), nil).ordered
          MyClass.foo.should == 7
        end
        it "registers method calls with arguments" do
          Hijacker.should_receive(:register).with(:bar, [2, "string"], "string", nil, kind_of(Class), nil).ordered
          MyClass.bar(2, "string").should == "string"
        end
        after(:each) do
          Hijacker.restore(MyClass)
        end
      end
      describe "forbidden classes (are not hijacked)" do
        [Array, Hash, String, Fixnum, Float, Numeric, Symbol].each do |forbidden|
          it "protects #{forbidden}" do
            expect {
              Hijacker.spy(forbidden)
            }.to raise_error
          end
        end
      end
    end
    describe "hijacking an object" do
      describe "instance methods" do
        let(:object) { MyClass.new }

        before(:each) do
          def object.my_method
            8
          end
          def object.my_method_with_args(a,b)
            b
          end
          Hijacker.spy(object)
        end
        it "registers method calls without arguments" do
          Hijacker.should_receive(:register).with(:foo, [], 7, nil, kind_of(MyClass), nil).ordered
          Hijacker.should_receive(:register).with(:my_method, [], 8, nil, kind_of(MyClass), nil).ordered

          object.foo.should == 7
          object.my_method.should == 8
        end
        it "registers method calls with arguments" do
          Hijacker.should_receive(:register).with(:bar, [2, "string"], "string", nil, kind_of(MyClass), nil).ordered
          Hijacker.should_receive(:register).with(:my_method_with_args, [2, "string"], "string", nil, kind_of(MyClass), nil).ordered

          object.bar(2, "string").should == "string"
          object.my_method_with_args(2, "string").should == "string"
        end
        it "works well with writers" do
          Hijacker.should_receive(:register).with(:foo=, [2], 2, nil, kind_of(MyClass), nil).ordered
          object.foo = 2
        end
        it "records exceptions" do
          Hijacker.should_receive(:register).with(:nasty, [], nil, kind_of(RuntimeError), kind_of(MyClass), nil).ordered
          object.nasty rescue nil
        end
        it "does not affect other instances of the object's class" do
          Hijacker.should_not_receive(:register)
          MyClass.new.foo.should == 7
        end
        after(:each) do
          Hijacker.restore(object)
        end
      end
    end

  end

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
