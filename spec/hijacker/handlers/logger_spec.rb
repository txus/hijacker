require 'spec_helper'

module Hijacker
  describe Logger do

    subject { Logger.new({:my => :option}) }

    it "initializes with options" do
      subject.opts.should == {:my => :option}
    end

    it "inherits from Handler" do
      subject.should be_kind_of(Handler)
    end

    it "implements the cli_options class method" do
      Hijacker::Logger.should respond_to(:cli_options)
      Hijacker::Logger.cli_options.should be_kind_of(Proc)
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

      it 'prints the received args' do
        out = StringIO.new
        subject.stub(:stdout).and_return out

        Time.stub(:now).and_return Time.parse('2010-11-20')

        subject.handle(*args)

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

          logger.handle(*args)

          out.string.should_not include("2010-11-20")
        end
      end
      context "when given :without_classes" do
        it 'discards the classes' do
          logger = Logger.new({:without_classes => true})

          out = StringIO.new
          logger.stub(:stdout).and_return out

          Time.stub(:now).and_return Time.parse('2010-11-20')

          logger.handle(*args)

          ["(Class)", "(Fixnum)", "(String)"].each do |str|
            out.string.should_not include(str)
          end
        end
      end
      context "when given a raised exception" do

        let(:args) do
          [:bar,
           [
            {:inspect => "2", :class => "Fixnum"},
            {:inspect => "\"string\"", :class => "String"},
           ],
           nil,
           {:inspect => "wrong number of arguments (0 for 2)", :class => "ArgumentError"},
           {:inspect => "MyClass", :class => "Class"}]
        end

        it "prints it instead of the return value" do
          out = StringIO.new
          subject.stub(:stdout).and_return out

          Time.stub(:now).and_return Time.parse('2010-11-20')

          subject.handle(*args)

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
           "and raised",
           "wrong number of arguments (0 for 2)",
           "(ArgumentError)"].each do |str|
            out.string.should include(str)
           end
        end

      end

    end
    
  end
end
