#hijacker

A little gem that hijacks any ruby object and broadcasts all its activity
to a particular hijacker server. Useful for logging and those awfully hardcore
debugging afternoons! There might be other uses to it, for sure. Just be
creative :)

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

    hijacker

And it will output the URI for this server. *Note this* and pass it to your
configuration block!

Some options you can pass to the server command:

    hijacker --without-timestamps (don't show the timestamps)
    hijacker --without-classes (don't show the object classes)
    hijacker --port 1234 (spawn the server in port 1234 rather than 8787)

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

Run this code and, if you look at the server output, you'll see nothing less
than...

    <a nice timestamp> MyClass (Class) received :new and returned #<MyClass:0x000000874> (MyClass)
    <a nice timestamp> #<MyClass:0x000000874> (MyClass) received :foo with 3
    (Fixnum), 4 (Fixnum) and returned 7

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
