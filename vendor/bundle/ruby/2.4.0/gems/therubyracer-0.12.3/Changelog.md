# Changelog

## Unreleased

* Support for unified Integer class in Ruby 2.4+ (thanks to @koic)

## 0.12.2 2015/04/06

* fix memory leak where weak hash map entries were not being cleaned
  up. Thanks to @SamSaffon

## 0.12.1 2014/02/03

* add `timeout` option to `V8::Context` to forcibly abort long running scripts (thanks to @SamSaffron)
* allow canonical require via  `require "therubyracer"` instead of oddball `require "v8"`(thanks @gaffneyc)

## 0.12.0 2013/08/20

* upgrade v8 to 3.16.4 (thanks to @ignisf)
* enable native (and functional) weakref implementation for MRI > 2.0
* expose low level interface for `V8::C::HeapStatistics#total_physical_size`

## 0.11.1 2013/01/04

* reintroduce the dependency on libv8
* libv8 can be disabled by installing it with the --with-system-v8 flag

## 0.11.0 2012/12/04

* upgrade V8 version to 3.11.8
* remove dependency on libv8. enable compilation against system v8
* complete re-write of low-level C layer for dramatically increased stability and performance
* more faithful and complete coverage of the low-level C API
* ease the building of binary gems
* official support for Rubinius
* ability to query V8 for memory usage and set resource constraints
* extensible conversion framework for thunking Ruby values to V8 and vice-versa
* extensible invocation framework for calling Ruby code (Proc, Method, etc...) from JavaScript
* extensible access framework for interacting with Ruby properties from JavaScript
* provide explicit context teardown for distributed cycles of garbage.


## 0.10.1 2012/04/05

* [bugfix] V8::Object#respond_to? did not call super

## 0.10.0 2012/03/28

* [incompatible] embedded lambdas now take JS `this` object as first object
* add sponsorship image to the README
* enable Travis CI

## 0.9.9 2011/11/08

* remove GCC specific C++ extension to fix llvm build.

## 0.9.8 2011/11/07

* let Rake version float again.

## 0.9.7 2011/10/06
* build fixes
* fix rake dependency at 0.8.7 while the Rake team sorts some shit out.

## 0.9.6 2011/10/06

* make build compatible with Gentoo

## 0.9.5 - 2011/10/05

* remove GCC specific code to enable build on BSD
* let Rake dependency float

## 0.9.4 - 2011/08/22

* Fix an issue with the compilation include paths which allowed compilation against conflicting libv8's

## 0.9.3 - 2011/08/11

* Better documentation for the C extension memory management
* Always lock V8 operations, always.
* GH-86 Context#[], Context#[]= always looks up values from the JavaScript scope, even when it's a Ruby object

## 0.9.2 - 2011/06/23

* fix issue with 1.8.7 where object allocation inside of GC was segfaulting

## 0.9.1 - 2011/06/17

* never perform V8 operations inside Ruby GC
* refactor locking interface
* add documentation for v8_handle

## 0.9.0 - 2011/06/10

* extract libv8 into installable binary for most platforms
* fix numerous memory leaks
* expose the V8 debugger via V8::C::Debug::EnableAgent()
* force UTf-8 encoding on strings returned from javascript in ruby 1.9
* remove deprecated evaluate() methods
* make the currently executing JavaScript stack available via Context#stack

## 0.8.1 - 2011/03/07

* upgrade to v8 3.1.8
* remove bin/v8 which conflicted with v8 executeable
* decruft all the crap that had accumulated in the gem
* Javascript Objects are now always mapped to the same V8::Object when read from the context

## 0.8.0 - 2010/12/02

* every V8 Context gets its own unique access strategy
* ruby methods and procs embedded in javascript always return the same function per context.
* ruby classes and subclasses are now all connected via the javascript prototype chain
* better error reporting on syntax errors
* upgrade to rspec 2
* several bug fixes and stability fixes

## 0.7.5 - 2010/08/03

* upgrade to V8 2.3.3
* property interceptors from ruby via [] and []=
* indexed property access via [] and []=
* property
* several bugfixes
* stability: eliminate many segfaults
* don't enumerate property setters such as foo= from javascript

## 0.7.4 - 2010/06/15

* bug fix for rvm ruby installs incorrectly detected as 32bit

## 0.7.3 - 2010/06/15

* don't catch SystemExit and NoMemoryError
* fix bug bundling gem

## 0.7.2 - 2010/06/14

* embed ruby classes as constructors
* support for rubinius
* uniform backtrace() function on JSError mixes the ruby
* String::NewSymbol() is now scriptable
* InstanceTemplate(), PrototypeTemplate(), Inherit() methods on v8::FunctionTemplate now scriptable.
* reuse the standard ruby object access template
* fix a bunch of compile warnings
* Store any ruby object in V8 with V8::C::External

## 0.7.1 - 2010/06/03

* Function#call() now uses the global scope for 'this' by default
* Function#methodcall() added to allow passing in 'this' object
* Function#new() method to invoke javascript constructor from ruby
* access javascript properties and call javascript methods from ruby
* bundled Jasmine DOM-Less browser testing framework.

* added Object::GetHiddenValue() to v8 metal
* added Handle::IsEmpty() to v8 metal
* fixed bug where iterating over arrays sometimes failed
* numerous bug /segfault fixes.

## 0.7.0 - 2010/05/31

* upgraded to V8 2.1.10
* added low level scripting interface for V8 objects
* ruby object property/method access is now implemented in ruby
* auto-convert javascript arrays to rb arrays and vice-versa
* auto-convert ruby hashes into javascript objects
* auto-convert javascript Date into ruby Time object and vice versa.
* better exception handling when passing through multiple language boundaries
* objects maintain referential integrity when passing objects from ruby to javascript and vice-versa
* added debug compile option for getting C/C++ backtraces whenever segfaults occur.
* official support for REE 1.8.7
* fixed numerous segfaults
* implemented V8::Value#to_s
* the global scope is available to every V8::Context as the 'scope' attribute
* properly convert ruby boolean values into V8 booleans.

## 0.6.3 - 2010/05/07

* FIX: linkage error on OSX /usr/bin/ruby

## 0.6.2 - 2010/05/06

* FIX: linkage error on OSX 10.5

## 0.6.1 - 2010/05/03

* call JavaScript functions from Ruby

## 0.6.0 - 2010/03/31

* ruby 1.9 compatible
* full featured command line bin/v8 and bin/therubyracer
* self validating install (v8 --selftest)
* Only dependency to build gem from source is rubygems.

## 0.5.5 - 2010/03/15

* fix string encoding issue that was breaking RHEL 5.x
* fix pthread linking issue on RHEL 5.2

## 0.5.4 - 2010/03/09

* add ext directory to gem require paths which was causing problems for non-binary gems

## 0.5.3 - 2010/03/01

* added full back trace to javascript code

## 0.5.2 - 2010/02/26

* added javascript shell (bin/therubyracer)
* added to_s method for embedded ruby objects
* added line number and file name to error message.

## 0.5.1 - 2010/02/17

* fix bug in 1.8.6 by creating Object#tap if it does not exist

## 0.5.0 - 2010/02/17

* support for Linux 64 bit

## 0.4.9 - 2010/02/16

* support for Linux 32 bit

## 0.4.8 - 2010/02/08

* expose line number and source name on JavascriptErrors.

## 0.4.5 - 2010/01/18

* case munging so that ruby methods(perl_case) are accessed through javascript in camelCase.
* access 0-arity ruby methods as javascript properties
* invoke ruby setters from javascript as properties
* contexts detect whether they are open or not and open when needed

## 0.4.4 - 2010/01/14

* Ruby objects embedded into javascript are passed back to ruby as themselves and not a wrapped V8 object wrapping a ruby object.
* Use any ruby object as the scope of eval().
* quick and dirty V8.eval() method added
* native objects have a reference to the context that created them.
* context now has equality check.
* expose InContext() and GetCurrent() methods.
* fix a couple of segmentation faults

## 0.4.3 - 2010/10/11

* access properties on Ruby objects with their camel case equivalents
* reflect JavaScript objects into Ruby and access their properties
* load JavaScript source from an IO object or by filename

## 0.4.2 - 2010/10/10

* embed Ruby Objects into Javascript and call their methods

## 0.4.1 - 2010/01/09

* embed bare Proc and Method objects into JavaScript and call them
* catch JavaScript exceptions from Ruby

## 0.4.0 - 2009/12/21

* evaluate JavaScript code from inside Ruby.
