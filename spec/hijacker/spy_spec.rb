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

  def nasty_method
    raise StandardError, "Something went wrong"
  end

end unless defined?(MyClass)

module Hijacker
  describe Spy do

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
            Hijacker.should_receive(:register).with(:baz=, [2], 2, nil, kind_of(MyClass), nil).ordered
            object.baz = 2
          end
          it "records exceptions" do
            Hijacker.should_receive(:register).with(:nasty_method, [], nil, kind_of(StandardError), kind_of(MyClass), nil).ordered
            expect {
              object.nasty_method
            }.to raise_error(StandardError)
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

  end
end
