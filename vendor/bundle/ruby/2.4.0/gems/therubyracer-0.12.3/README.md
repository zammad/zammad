# therubyracer

[![Gem Version](https://badge.fury.io/rb/therubyracer.png)](http://badge.fury.io/rb/therubyracer)
[![Build Status](https://travis-ci.org/cowboyd/therubyracer.png?branch=master)](https://travis-ci.org/cowboyd/therubyracer)
[![Build status](https://ci.appveyor.com/api/projects/status/aqw06doke164dca7?svg=true)](https://ci.appveyor.com/project/cowboyd/therubyracer)
[![Dependency Status](https://gemnasium.com/cowboyd/therubyracer.png)](https://gemnasium.com/cowboyd/therubyracer)
[![Join the chat at https://gitter.im/cowboyd/therubyracer](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/cowboyd/therubyracer?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


* GitHub Project: [http://github.com/cowboyd/therubyracer](http://github.com/cowboyd/therubyracer)
* Mailing List: [http://groups.google.com/group/therubyracer](http://groups.google.com/group/therubyracer)
* Documentation: [GitHub Wiki](https://github.com/cowboyd/therubyracer/wiki) and [RubyDoc](http://rubydoc.info/gems/therubyracer)

### DESCRIPTION

Embed the V8 JavaScript interpreter into Ruby.

### FEATURES

* Evaluate JavaScript from within Ruby
* Embed your Ruby objects into the JavaScript world
* Manipulate JavaScript objects and call JavaScript functions from Ruby
* API compatible with the The Ruby Rhino (for JRuby: http://github.com/cowboyd/therubyrhino)

### SYNOPSIS

    gem install therubyracer

then in your Ruby code

    require 'v8'

or if using bundler (as with Rails), add the following to your Gemfile

    gem "therubyracer"

evaluate some simple JavaScript

    cxt = V8::Context.new
    cxt.eval('7 * 6') #=> 42

access values inside your JavaScript context from Ruby

    cxt.eval 'var val = {num: 5, isTruthy: function (arg) { return !!arg }}'
    val = cxt[:val] #=> V8::Object
    cxt[:val] == cxt.scope.val #=> true
    val.num #=> 5
    val.isTruthy(1) #=> true

this includes references to JavaScript functions

    truthy = val[:isTruthy] #=> V8::Function
    truthy.call(' ') #=> true
    truthy.call(0) #=> false


embed values into the scope of your context

    cxt['foo'] = "bar"
    cxt.eval('foo') # => "bar"

embed Ruby code into your scope and call it from JavaScript

    cxt["say"] = lambda {|this, word, times| word * times}
    cxt.eval("say('Hello', 3)") #=> HelloHelloHello

embed a Ruby object into your scope and access its properties/methods
from JavaScript

    class MyMath
      def plus(lhs, rhs)
        lhs + rhs
      end
    end

    cxt['math'] = MyMath.new
    cxt.eval("math.plus(20,22)") #=> 42

make a Ruby object *be* your global JavaScript scope.

    math = MyMath.new
    V8::Context.new(:with => math) do |cxt|
      cxt.eval("plus(20,22)") #=> 42
    end

you can do the same thing with Object#eval_js

    math.eval_js("plus(20,22)")

### Different ways of loading JavaScript source

In addition to just evaluating strings, you can also use streams, such
as files.

evaluate bytes read from any File/IO object:

    File.open("mysource.js") do |file|
      cxt.eval(file, "mysource.js")
    end

or load it by filename

    cxt.load("mysource.js")

### Safe by default, dangerous by demand

The Ruby Racer is designed to let you evaluate JavaScript as safely as
possible unless you tell it to do something more dangerous. The
default context is a hermetically sealed JavaScript environment with
only the standard JavaScript objects and functions. Nothing from the
Ruby world is accessible at all.

For Ruby objects that you explicitly embed into JavaScript, by default
only the _public_ methods _below_ `Object` are exposed by default.
E.g.

    class A
      def a
        "a"
      end

      def to_s
        super
      end
    end

    class B < A
      def b
        "b"
      end
    end


    V8::Context.new do |cxt|
      cxt['a'] = A.new
      cxt['b'] = B.new
      cxt.eval("a.a") # => 'a'
      cxt.eval("b.b") # => 'b'
      cxt.eval("b.a") # => 'a'
      cxt.eval("b.to_s") # => #<B:0x101776be8> (because A explicitly defined it)
      cxt.eval("b.object_id") #=> undefined, object_id is on Object
    end

If needed, you can override the [Ruby Access][access] to allow whatever
behavior you'd like.

[access]:https://github.com/cowboyd/therubyracer/blob/master/lib/v8/access.rb

More documentation can be found on the [GitHub wiki](https://github.com/cowboyd/therubyracer/wiki)

### Protecting Your CPU cycles

When running untrusted JavaScript code, you not only have to protect
which functions it has access to, but also how much of your CPU it can
consume. Take this simple, yet thoroughly malicious script:

```javascript
while (true) {}
```

It will loop forever and never return control to the calling Ruby
thread. To protect against such JavaScript code that either
deliberately or accidentally runs longer that it should, you can
set an explicit timeout on your context. If the code runs longer that
the allowed timeout, then it will throw an exception. Note that this
exception could be raised at any point in the execution of the
JavaScript.

To specify the timeout (in milliseconds), pass in the `timeout` option
to the constructor.

```ruby
cxt = V8::Context.new timeout: 700
cxt.eval "while (true);" #= exception after 700ms!
```

### PREREQUISITES

The Ruby Racer requires the V8 Javascript engine, but it offloads the
handling of this dependency to the
[libv8](https://github.com/cowboyd/libv8) gem. Because libv8 is now a
gem dependency, you do not need a separate libv8 entry in your
project's Gemfile.

Please see [libv8](https://github.com/cowboyd/libv8) for V8 runtime
installation options.

### DEVELOP

    git clone git://github.com/cowboyd/therubyracer.git
    cd therubyracer
    bundle install
    rake compile

### Sponsored by

<a href="http://thefrontside.net">![The Frontside](http://github.com/cowboyd/therubyracer/raw/master/thefrontside.png)</a>

### LICENSE:

(The MIT License)

Copyright (c) 2009,2010,2011,2012 Charles Lowell

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[1]: https://github.com/cowboyd/libv8
[2]: http://code.google.com/p/v8/wiki/BuildingWithGYP
