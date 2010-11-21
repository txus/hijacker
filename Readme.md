#hijacker

A little gem that hijacks any ruby object and broadcasts all its activity
to a particular hijacker server. The server exposes a special handler object
which then does fun things with the received data!

For example, by now there is only one handler: Logger. This handler shows the
received activity in the server output with fancy logging-style colors. Could
be quite useful for those awfully long debugging afternoons!

Of course, you can write your own handlers to do whatever you want with the
data: maybe record how many arguments do your methods accept on average, log
into disk any method calls containing a certain type of argument... just be
creative! :)

(See the "Extending hijacker blabla" part below to know how to write your own
handlers)

Hijacker is tested with Ruby 1.8.7, 1.9.2, JRuby 1.5.3 and Rubinius 1.1.

##Install and configure

In your Gemfile:

    gem 'hijacker'

If you are using Rails, you might want to put this configuration snippet in an
initializer or something (you can always put it in any other part of the code
otherwise, as long as it's before hijacking any object):

    Hijacker.configure do
      uri '<YOUR HIJACKER SERVER URI>'
    end

And that's it! Oooor not. You have to spawn your server. In the command line:

    hijacker <handler>

Where <handler> must be a registered handler (for now there is only 'logger').
So you type:

    hijacker logger

And it will output the URI for this super fancy hijacker logging server.
*Remember this URI* and pass it to your configuration block!

Some options you can pass to the server command:

    hijacker <handler> --port 1234 (spawn the server in port 1234 rather than 8787)

Specific handlers can accept specific options. Logger accepts these:

    hijacker logger --without-timestamps (don't show the timestamps)
    hijacker logger --without-classes (don't show the object classes)

##Ok, and now for some hijacking action!

    require 'hijacker'  # You don't have to when using Bundler :)
   
    class MyClass
      def foo(bar, baz)
        bar + baz 
      end
    end

    some_object = Object.new

    # These are the important lines:

    Hijacker.spy(some_object)
    Hijacker.spy(MyClass)

    instance = MyClass.new
    instance.foo(3, 4)

Run this code and, given we are using the Logger handler, if you look at the server output, you'll see nothing less than...

    <a nice timestamp> MyClass (Class) received :new and returned #<MyClass:0x000000874> (MyClass)
    <a nice timestamp> #<MyClass:0x000000874> (MyClass) received :foo with 3 (Fixnum), 4 (Fixnum) and returned 7 (Fixnum)

But in a nice set of colors.

If you want to un-hijack any object, just call #restore:

    Hijacker.restore(MyClass)
    Hijacker.restore(some_object)

If you don't want to have to remember every hijacked object you have to call
restore on it, you can just spy a particular object within the duration of a block:

    Hijacker.spying(MyClass) do
      # inside this block, MyClass will be spied
    end
    # here not anymore

Awesome! You can fine-tune your spying, for example by only spying on instance
methods or singleton methods only:

    Hijacker.spy(MyClass, :only => :instance_methods) # or :singleton_methods

And, last but not least... you can specify a *particular hijacker server* for
a *particular object* you are spying on!

    # All activity on MyClass and its instances will
    # be sent to druby://localhost:9999
    Hijacker.spy(MyClass, :uri => 'druby://localhost:9999')

    # But for example, the activity of some_object will
    # be sent to the default uri specified in the configuration
    # back earlier (remember?)
    Hijacker.spy(some_object)

Of course, you can specify a particular server uri for a block, with #spying:

    Hijacker.spying(foo_object, :uri => 'druby://localhost:1234') do
      # all the activity of foo_object inside this block
      # will be sent to the hijacker server on druby://localhost:1234
    end
  
##Extending hijacker with moar handlers

It is really easy to write your own handlers. Why don't you write one and send
me a pull request? I mean now. What are you waiting for, why are you still reading?

Ok, maybe a bit of explanation on that. Handlers live here:

    lib/hijacker/handlers/your_handler.rb

They are autoloaded and automatically registered, so all you have to do is
write them like this:


    module Hijacker
      class MyHandler < Handler # Yes, you have to subclass Hijacker::Handler!

        # You must implement a class method named cli_options which must
        # return a Trollop-friendly Proc, for command-line options parsing.
        #
        # These options can be accessed within the #handle method by calling
        # the opts method.
        #
        def self.cli_options
          Proc.new {
            opt :without_foo, "Don't use foo to handle the method name"
            opt :using_bar, "Use bar as much as you can"
          }
        end

        # This is the most important method. This is what is called every time
        # a method call is performed on a hijacked object. The received params
        # look like this:
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
        def handle(method, args, retval, object)
          # Do what you want with these!
        end

      end
    end

Try to think of creative uses of hijacker, write your own handlers and send
them to me ZOMG I CAN HAZ MOAR HENDLARZ

##Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add specs for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  If you want to have your own version, that is fine but bump version
  in a commit by itself I can ignore when I pull.
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 Josep M. Bach. See LICENSE for details.
