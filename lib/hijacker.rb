require 'drb'
require 'trollop'
require 'hijacker/config'
require 'hijacker/logger'

module Hijacker

  # Methods that won't be hijacked in any case
  REJECTED_METHODS = (Object.instance_methods | Module.methods | %w{< <= > >= __original_[\w\d]+ [^\w\d]+})
  FORBIDDEN_CLASSES = [Array, Hash, String, Fixnum, Float, Numeric, Symbol, Proc, Class, Object, BasicObject, Module]

  class << self

    def spying(*args, &block)
      raise "No block given" unless block
      Hijacker.spy(*args)
      block.call
      Hijacker.restore(args.first)
    end

    def spy(object, options = {})
      raise "Cannot spy on the following forbidden classes: #{FORBIDDEN_CLASSES.map(&:to_s).join(', ')}" if FORBIDDEN_CLASSES.include?(object)
      rejection = /^(#{REJECTED_METHODS.join('|')})/
      only = options[:only]
      uri = options[:uri]
      custom_rejection = options[:reject] if options[:reject].is_a?(Regexp)
       
      inst_methods = guess_instance_methods_from(object).reject{|m| (m =~ rejection)}.reject{|m| m =~ custom_rejection}
      sing_methods = guess_class_methods_from(object).reject{|m| m =~ rejection}.reject{|m| m =~ custom_rejection}

      receiver = if object.is_a?(Class)
        object
      else
        (class << object; self; end)
      end

      inst_methods.each do |met|
          receiver.send(:alias_method, :"__original_#{met}", :"#{met}")
          receiver.send(:undef_method, :"#{met}")
          receiver.class_eval <<EOS
            def #{met}(*args, &blk)
              __original_#{met}(*args,&blk).tap do |retval|
                Hijacker.register :#{met}, args, retval, self, #{uri.inspect}
              end
            end
EOS
      end unless options[:only] == :singleton_methods

      receiver = (class << object; self; end)
      sing_methods.each do |met|
          receiver.send(:alias_method, :"__original_#{met}", :"#{met}")
          receiver.send(:undef_method, :"#{met}")
          receiver.class_eval <<EOS
            def #{met}(*args, &blk)
              __original_#{met}(*args,&blk).tap do |retval|
                Hijacker.register :#{met}, args, retval, self, #{uri.inspect}
              end
            end
EOS
      end unless options[:only] == :instance_methods

    end

    def restore(object)
      receiver = if object.is_a?(Class)
        object
      else
        (class << object; self; end)
      end
      guess_instance_methods_from(object).select{|m| m =~ /__original_/}.each do |met|
        met = met.to_s.gsub!("__original_", "")
        receiver.send(:undef_method, :"#{met}")
        receiver.send(:alias_method, :"#{met}", :"__original_#{met}")
      end

      receiver = (class << object; self; end)
      guess_class_methods_from(object).select{|m| m =~ /__original_/}.each do |met|
        met = met.to_s.gsub!("__original_", "")
        receiver.send(:undef_method, :"#{met}")
        receiver.send(:alias_method, :"#{met}", :"__original_#{met}")
      end
    end

    def register(method, args, retval, object, uri = nil)
      args.map! do |arg|
        {:inspect => arg.inspect, :class => arg.class.name}
      end
      retval = {:inspect => retval.inspect, :class => retval.class.name}
      object = {:inspect => object.inspect, :class => object.class.name}

      server = DRbObject.new nil, (uri || self.drb_uri)
      server.log method, args, retval, object
    end

    private

    def guess_instance_methods_from(object)
      if object.is_a?(Class)
        object.instance_methods
      else
        object.methods
      end
    end

    def guess_class_methods_from(object)
      if object.is_a?(Class)
        object.methods
      else
        []
      end
    end

  end

end
