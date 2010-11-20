require 'spec_helper'

module Hijacker
  describe Logger do

    subject { Logger.new({:my => :option}) }

    it "initializes with options" do
      subject.opts.should == {:my => :option}
    end

    describe "#log" do

      let(:args) do
        [:bar,
         [
          {:inspect => "2", :class => "Fixnum"},
          {:inspect => "\"string\"", :class => "String"},
         ],
         {:inspect => "\"retval\"", :class => "String"},
         {:inspect => "MyClass", :class => "Class"}]
      end

      it 'prints the received args' do
        out = StringIO.new
        subject.stub(:stdout).and_return out

        Time.stub(:now).and_return Time.parse('2010-11-20')

        subject.log(*args)

        ["00:00:00 +0100",
         "MyClass",
         "(Class)",
         "received",
         ":bar",
         "with",
         "2",
         "(Fixnum)",
         "\"string\"",
         "(String)",
         "and returned",
         "\"retval\"",
         "(String)"].each do |str|
          out.string.should include(str)
         end
      end
      context "when given :without_timestamps" do
        it 'discards the timestamps' do
          logger = Logger.new({:without_timestamps => true})

          out = StringIO.new
          logger.stub(:stdout).and_return out

          Time.stub(:now).and_return Time.parse('2010-11-20')

          logger.log(*args)

          out.string.should_not include("2010-11-20")
        end
      end
      context "when given :without_classes" do
        it 'discards the classes' do
          logger = Logger.new({:without_classes => true})

          out = StringIO.new
          logger.stub(:stdout).and_return out

          Time.stub(:now).and_return Time.parse('2010-11-20')

          logger.log(*args)

          ["(Class)", "(Fixnum)", "(String)"].each do |str|
            out.string.should_not include(str)
          end
        end
      end
    end
    
  end
end
