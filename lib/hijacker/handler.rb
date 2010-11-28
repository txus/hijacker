module Hijacker
  class Handler
    # Your custom handlers need to respond to this class method, which will be
    # expected to return a proc meant to be sent to Trollop during the command
    # line parsing. For example, the Logger handler implements cli_options like
    # this:
    #
    #     def self.cli_options
    #       Proc.new {
    #         opt :without_classes, "Don't show classes of objects"
    #         opt :without_timestamps, "Don't show timestamps"
    #       }
    #     end

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
      #   retval    {:inspect => ':bar', :class => 'Symbol'}
      #
      #   object    {:inspect => '#<MyClass:0x003457>', :class => 'MyClass'}
      #
      raise NotImplementedError.new("You are supposed to subclass Handler")
    end

    class << self

      @@handlers = []

      def register_handler(handler)
        handler.match(/handlers\/(\w+)/)
        handler = $1.strip if $1
        @@handlers << handler
      end
      def handlers
        @@handlers
      end
    end
  end
end

# Automatically load all handlers in the following paths:
#
#     ./.hijacker/**/*.rb
#     ~/.hijacker/**/*.rb
#     lib/handlers/**/*.rb
#
(Dir[File.dirname(File.join(Dir.pwd, '.hijacker', '**', '*.rb'))] + \
Dir[File.dirname(File.expand_path(File.join('~', '.hijacker', '**', '*.rb')))] + \
Dir[File.dirname(File.join(File.dirname(__FILE__), 'handlers', '**', '*.rb'))]).entries.each do |handler|
  require(handler) && Hijacker::Handler.register_handler(handler)
end
