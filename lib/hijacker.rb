require 'drb'
require 'trollop'
require 'hijacker/exceptions'
require 'hijacker/config'
require 'hijacker/handler'

module Hijacker

  # Methods that won't be hijacked in any case
  REJECTED_METHODS = (Object.instance_methods | Module.methods | %w{__original_[\w\d]+})
  FORBIDDEN_CLASSES = [Array, Hash, String, Fixnum, Float, Numeric, Symbol, Proc, Class, Object, Module]

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

    def register(method, args, retval, raised, object, uri = nil)
      args.map! do |arg|
        {:inspect => arg.inspect, :class => arg.class.name}
      end
      if raised
        raised = {:inspect => raised.message, :class => raised.class.name}
      else
        retval = {:inspect => retval.inspect, :class => retval.class.name}
      end
      object = {:inspect => object.inspect, :class => object.class.name}

      server = DRbObject.new nil, (uri || self.drb_uri)
      server.handle method, args, retval, raised, object
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

    def define_hijacked(methods, receiver, uri)
      methods.each do |met|
        receiver.send(:alias_method, :"__original_#{met}", :"#{met}")
        receiver.send(:undef_method, :"#{met}")
        writer = (met =~ /=$/)
        receiver.class_eval <<EOS
          def #{met}(#{writer ? 'arg' : '*args, &blk'})
            begin
              __original_#{met}(#{writer ? 'arg' : '*args, &blk'}).tap do |retval|
                Hijacker.register :#{met}, #{writer ? '[arg]' : 'args' }, retval, nil, self, #{uri.inspect}
              end
            rescue=>error
              Hijacker.register :#{met}, #{writer ? '[arg]' : 'args' }, nil, error, self, #{uri.inspect}
              raise error
            end
          end
EOS
      end
    end

  end

end
