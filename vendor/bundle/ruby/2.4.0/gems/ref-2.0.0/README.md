# Ref

[![Gem Version](https://badge.fury.io/rb/ref.svg)](http://badge.fury.io/rb/ref) [![Build Status](https://travis-ci.org/ruby-concurrency/ref.svg?branch=master)](https://travis-ci.org/ruby-concurrency/ref) [![Coverage Status](https://img.shields.io/coveralls/ruby-concurrency/ref/master.svg)](https://coveralls.io/r/ruby-concurrency/ref) [![Code Climate](https://codeclimate.com/github/ruby-concurrency/ref.svg)](https://codeclimate.com/github/ruby-concurrency/ref) [![Dependency Status](https://gemnasium.com/ruby-concurrency/ref.svg)](https://gemnasium.com/ruby-concurrency/ref) [![License](https://img.shields.io/badge/license-MIT-green.svg)](http://opensource.org/licenses/MIT) [![Gitter chat](http://img.shields.io/badge/gitter-join%20chat%20%E2%86%92-brightgreen.svg)](https://gitter.im/ruby-concurrency/concurrent-ruby)

This library provides object references for Ruby as well as some common utilities for working with references. Object references are used to point to other objects and come in three distinct flavors that interact differently with the garbage collector.

* `Ref::StrongReference` - This is a plain old pointer to another object.
* `Ref::WeakReference` - This is a pointer to another object, but it is not seen by the garbage collector and the memory used by the object can be reclaimed at any time.
* `Ref::SoftReference` - This is similar to a weak reference, but the garbage collector is not as eager to reclaim the referenced object.

All of these classes extend from a common `Ref::Reference` class and have a common interface.

Weak and soft references are useful when you have instantiated objects that you may want to use again but can recreate if necessary. Since the garbage collector determines when to reclaim the memory used by the objects, you don't need to worry about bloating the Ruby heap.

## Example Usage

```ruby
ref = Ref::WeakReference.new("hello")
ref.object # should be "hello"
ObjectSpace.garbage_collect
ref.object # should be nil (assuming the garbage collector reclaimed the reference)
```

## Goodies

This library also includes tools for some common uses of weak and soft references.

* `Ref::WeakKeyMap` - A map of keys to values where the keys are weak references
* `Ref::WeakValueMap` - A map of keys to values where the values are weak references
* `Ref::SoftKeyMap` - A map of keys to values where the keys are soft references
* `Ref::SoftValueMap` - A map of keys to values where the values are soft references
* `Ref::ReferenceQueue` - A thread safe implementation of a queue that will add references to itself as their objects are garbage collected.

## Problems with WeakRef

Ruby does come with the `WeakRef` class in the standard library. However, there are [issues with this class](https://bugs.ruby-lang.org/issues/4168) across several different Ruby runtimes. This gem provides a common interface to weak references that works across MRI, Ruby Enterprise Edition, YARV, JRuby and Rubinius.

1. Rubinius - Rubinius implements `WeakRef` with a lighter weight version of delegation and works very well.
2. YARV 1.9 - `WeakRef` is unsafe to use because the garbage collector can run in a different system thread than a thread allocating memory. This exposes a bug where a `WeakRef` may end up pointing to a completely different object than it originally referenced.
3. MRI Ruby 2.0+ has a good implementation of `WeakRef`.

