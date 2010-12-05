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
    let(:object) { MyClass.new }
    let(:klass) { MyClass }
    let(:inst_methods) { [:foo, :bar] }
    let(:sing_methods) { [:foo, :bar] }

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

    describe "#spy" do

      context "when given a class" do
        before(:each) do
          Hijacker.should_receive(:guess_instance_methods_from).with(klass).and_return(inst_methods)
          Hijacker.should_receive(:guess_singleton_methods_from).with(klass).and_return(sing_methods)
        end

        let(:metaclass) { (class << klass; self; end) }

        it 'calls define_hijacked on all methods' do
          Hijacker.should_receive(:define_hijacked).with(inst_methods, klass, nil).once
          Hijacker.should_receive(:define_hijacked).with(sing_methods, metaclass, nil).once

          Hijacker.spy(klass)    
        end
        context "with :only => :singleton_methods" do
          it 'calls define_hijacked only on singleton methods' do
            Hijacker.should_not_receive(:define_hijacked).with(inst_methods, klass, nil)
            Hijacker.should_receive(:define_hijacked).with(sing_methods, metaclass, nil).once

            Hijacker.spy(klass, :only => :singleton_methods)    
          end
        end
        context "with :only => :instance_methods" do
          it 'calls define_hijacked only on instance methods' do
            Hijacker.should_receive(:define_hijacked).with(inst_methods, klass, nil)
            Hijacker.should_not_receive(:define_hijacked).with(sing_methods, metaclass, nil)

            Hijacker.spy(klass, :only => :instance_methods)
          end
        end
      end
      context "when given an object" do
        before(:each) do
          Hijacker.stub(:guess_instance_methods_from).with(object).and_return(inst_methods)
          Hijacker.stub(:guess_singleton_methods_from).with(object).and_return(sing_methods)
        end

        let(:metaclass) { (class << object; self; end) }
        it 'calls define_hijacked on all methods' do
          Hijacker.should_receive(:define_hijacked).with(inst_methods, metaclass, nil).once
          Hijacker.should_receive(:define_hijacked).with(sing_methods, metaclass, nil).once

          Hijacker.spy(object)    
        end
        context "with :only => :singleton_methods" do
          it 'calls define_hijacked only on singleton methods' do
            Hijacker.should_receive(:define_hijacked).with(sing_methods, metaclass, nil).once

            Hijacker.spy(object, :only => :singleton_methods)
          end
        end
        context "with :only => :instance_methods" do
          it 'calls define_hijacked only on instance methods' do
            Hijacker.should_receive(:define_hijacked).with(inst_methods, metaclass, nil).once

            Hijacker.spy(object, :only => :instance_methods)
          end
        end
      end
      context "when given a forbidden class" do
        it "raises" do
          expect {
            Hijacker.spy(Array)
          }.to raise_error(StandardError)
        end
      end
      it "rejects methods from REJECTED_METHODS constant" do
        inst_methods_with_some_rejected = inst_methods | [:instance_eval, :__original_something]
        sing_methods_with_some_rejected = sing_methods | [:instance_eval, :__original_something]

        Hijacker.should_receive(:guess_instance_methods_from).with(object).and_return(inst_methods_with_some_rejected)
        Hijacker.should_receive(:guess_singleton_methods_from).with(object).and_return(sing_methods_with_some_rejected)

        Hijacker.should_receive(:define_hijacked).with(inst_methods, kind_of(Class), nil).once
        Hijacker.should_receive(:define_hijacked).with(sing_methods, kind_of(Class), nil).once

        Hijacker.spy(object)
      end
    end

    describe "#restore" do
      it "restores all methods from the object" do
        inst_methods_with_some_hijacked = inst_methods | [:__original_foo, :__original_bar]
        sing_methods_with_some_hijacked = sing_methods | [:__original_foo, :__original_bar]
        receiver = (class << object; self; end)

        Hijacker.should_receive(:guess_instance_methods_from).with(object).and_return(inst_methods_with_some_hijacked)
        Hijacker.should_receive(:guess_singleton_methods_from).with(object).and_return(sing_methods_with_some_hijacked)

        receiver.should_receive(:undef_method).with(:foo).twice # instance and singleton methods
        receiver.should_receive(:alias_method).with(:foo, :__original_foo).twice
        receiver.should_receive(:undef_method).with(:bar).twice
        receiver.should_receive(:alias_method).with(:bar, :__original_bar).twice

        Hijacker.restore(object)
      end
    end


  end
end
