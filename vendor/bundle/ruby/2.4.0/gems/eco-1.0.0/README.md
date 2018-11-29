Ruby Eco
========

Ruby Eco is a bridge to the official
[Eco](https://github.com/sstephenson/eco) compiler for embedded
CoffeeScript templates.

```ruby
require "eco"

Eco.compile(File.read("template.eco"))
# => "function(...) {...}"

context = Eco.context_for("Hello <%= @name %>")
context.call("render", :name => "Sam")
# => "Hello Sam"

Eco.render("Hello <%= @name %>", :name => "world")
# => "Hello world"
```

Installation
------------

    $ gem install eco


Dependencies
------------

This library depends on the `eco-source` gem which is updated any time
a new version of Eco is released. (The `eco-source` gem's version
number is synced with each official Eco release.) This way you can
build against different versions of Eco by requiring the correct
version of the `eco-source` gem.

In addition, you can use this library with unreleased versions of Eco
by setting the `ECO_SOURCE_PATH` environment variable:

    export ECO_SOURCE_PATH=/path/to/eco/dist/eco.js


### Ruby CoffeeScript

The [Ruby CoffeeScript](https://github.com/josh/ruby-coffee-script)
library is used to load the CoffeeScript compiler source. See the
[README](https://github.com/josh/ruby-coffee-script/blob/master/README.md)
for information on loading a specific version of the CoffeeScript
compiler.

### ExecJS

The [ExecJS](https://github.com/sstephenson/execjs) library is used to
automatically choose the best JavaScript engine for your
platform. Check out its
[README](https://github.com/sstephenson/execjs/blob/master/README.md)
for a complete list of supported engines.
