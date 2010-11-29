require 'spec_helper'

module Hijacker
  describe MethodDefiner do

    describe "#define_hijacked" do
      let(:receiver) do
        class SomeClass
          def foo
            7
          end
          def bar(a, b)
            a + b
          end
          def baz=(value)
            @baz = value
          end
          def method_with_block(argument)
            yield if block_given?
          end
          def method_that_raises
            raise StandardError, "Something went wrong"
          end
        end
        SomeClass
      end

      before(:each) do
        Hijacker.stub(:register)
      end

      after(:each) do
        Hijacker.restore(receiver)
      end

      it 'saves original methods on the receiver' do
        Hijacker.send(:define_hijacked, [:foo, :bar], receiver, nil)
        instance = receiver.new 
        instance.should respond_to(:__original_foo, :__original_bar)
        instance.should_not respond_to(:__original_baz)
      end

      it 'creates aliased methods' do
        Hijacker.send(:define_hijacked, [:foo, :baz=], receiver, nil)
        instance = receiver.new

        instance.should_receive(:__original_foo).once
        instance.foo
        instance.should_not_receive(:__original_bar)
        instance.bar(9,10)
        instance.should_receive(:__original_baz=)
        instance.baz = 3
      end

      describe "registering method calls" do
        context "with no arguments" do
          it "registers the method call" do
            Hijacker.send(:define_hijacked, [:foo], receiver, nil)
            instance = receiver.new
            Hijacker.should_receive(:register).with :foo,
                                                    [],
                                                    7,
                                                    nil,
                                                    instance,
                                                    nil
            instance.foo.should == 7
          end
        end
        context "with arguments" do
          it "registers the method call" do
            Hijacker.send(:define_hijacked, [:bar], receiver, nil)
            instance = receiver.new
            Hijacker.should_receive(:register).with :bar,
                                                    [1,2],
                                                    3,
                                                    nil,
                                                    instance,
                                                    nil
            instance.bar(1,2).should == 3
          end
        end
        context "with arguments and a block" do
          it "registers the method call" do
            Hijacker.send(:define_hijacked, [:method_with_block], receiver, nil)
            instance = receiver.new
            Hijacker.should_receive(:register).with :method_with_block,
                                                    [1,kind_of(Proc)],
                                                    3,
                                                    nil,
                                                    instance,
                                                    nil
            instance.method_with_block(1) do
              3
            end.should == 3
          end
        end
        context "raising an exception" do
          it "registers the method call" do
            Hijacker.send(:define_hijacked, [:method_that_raises], receiver, nil)
            instance = receiver.new
            Hijacker.should_receive(:register).with :method_that_raises,
                                                    [],
                                                    nil,
                                                    kind_of(StandardError),
                                                    instance,
                                                    nil
            expect {
              instance.method_that_raises
            }.to raise_error(StandardError)
          end
        end
      end
    end
  end
end
