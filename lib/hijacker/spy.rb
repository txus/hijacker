module Hijacker
  module Spy

    REJECTED_METHODS = (Object.instance_methods | Module.methods | %w{__original_[\w\d]+})
    FORBIDDEN_CLASSES = [Array, Hash, String, Fixnum, Float, Numeric, Symbol, Proc, Class, Object, Module]

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

      inst_methods = guess_instance_methods_from(object).reject{|m| m.to_s =~ rejection}.reject{|m| m.to_s =~ custom_rejection}
      sing_methods = guess_singleton_methods_from(object).reject{|m| m.to_s =~ rejection}.reject{|m| m.to_s =~ custom_rejection}

      receiver = if object.is_a?(Class)
        object
      else
        (class << object; self; end)
      end

      define_hijacked(inst_methods, receiver, uri) unless options[:only] == :singleton_methods
      receiver = (class << object; self; end)
      define_hijacked(sing_methods, receiver, uri) unless options[:only] == :instance_methods

    end

    def restore(object)
      receiver = if object.is_a?(Class)
        object
      else
        (class << object; self; end)
      end
      guess_instance_methods_from(object).select{|m| m.to_s =~ /__original_/}.each do |met|
        met = met.to_s.gsub!("__original_", "")
        receiver.send(:undef_method, :"#{met}")
        receiver.send(:alias_method, :"#{met}", :"__original_#{met}")
      end

      receiver = (class << object; self; end)
      guess_singleton_methods_from(object).select{|m| m.to_s =~ /__original_/}.each do |met|
        met = met.to_s.gsub!("__original_", "")
        receiver.send(:undef_method, :"#{met}")
        receiver.send(:alias_method, :"#{met}", :"__original_#{met}")
      end
    end

    private

    def guess_instance_methods_from(object)
      if object.is_a?(Class)
        object.instance_methods
      else
        object.methods
      end
    end

    def guess_singleton_methods_from(object)
      if object.is_a?(Class)
        object.methods
      else
        []
      end
    end

  end
end
