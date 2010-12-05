require 'drb'
require 'trollop'
require 'hijacker/exceptions'
require 'hijacker/method_definer'
require 'hijacker/spy'
require 'hijacker/config'
require 'hijacker/handler'

module Hijacker

  class << self

    include MethodDefiner
    private :define_hijacked

    include Spy
    public :spy, :spying, :restore

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

  end

end
