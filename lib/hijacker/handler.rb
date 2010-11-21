module Hijacker
  class Handler
    # Make dRuby send Handler instances as dRuby references,
    # not copies.
    include DRb::DRbUndumped

    attr_reader :opts

    def initialize(opts)
      @opts = opts
    end

    def handle(method, args, retval, object)
      # Parameters received
      #
      #   method    :foo
      #
      #   args      [{:inspect => '3', :class => 'Fixnum'},
      #              {:inspect => '"string"', :class => 'String'}]
      #
      #   retval    [{:inspect => ':bar', :class => 'Symbol'}]
      #
      #   object    [{:inspect => '#<MyClass:0x003457>', :class => 'MyClass'}]
      #
      raise NotImplementedError.new("You are supposed to subclass Handler")
    end

  end
end

# Automatically load all handlers
Dir[File.dirname(File.join(File.dirname(__FILE__), 'handlers', '**', '*.rb'))].entries.each do |handler|
  require handler
end
