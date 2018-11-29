# Ruby Argon2 Gem

This Ruby Gem provides FFI bindings, and a simplified interface, to the Argon2 algorithm. [Argon2](https://github.com/P-H-C/phc-winner-argon2) is the official winner of the Password Hashing Competition, a several year project to identify a successor to bcrypt/PBKDF/scrypt methods of securely storing passwords. This is an independant project and not official from the PHC team.


[![Build Status](https://travis-ci.org/technion/ruby-argon2.svg?branch=master)](https://travis-ci.org/technion/ruby-argon2)
[![Code Climate](https://codeclimate.com/github/technion/ruby-argon2/badges/gpa.svg)](https://codeclimate.com/github/technion/ruby-argon2)
[![Test Coverage](https://codeclimate.com/github/technion/ruby-argon2/badges/coverage.svg)](https://codeclimate.com/github/technion/ruby-argon2/coverage)

## Design

This project has several key tenants to its design:

* The reference Argon2 implementation is to be used "unaltered". To ensure compliance with this goal, and encourage regular updates from upstream, the upstream library is implemented as a git submodule, and is intended to stay that way.
* The FFI interface is kept as slim as possible, with wrapper classes preferred to implementing context structs in FFI
* Security and maintainability take top priority. This can have an impact on platform support. A PR that contains platform specific code paths is unlikely to be accepted.
* Tested platforms are MRI Ruby 2.2, 2.3 and JRuby 9000. No assertions are made on other platforms.
* Errors from the C interface are raised as Exceptions. There are a lot of exception classes, but they tend to relate to things like very broken input, and code bugs. Calls to this library should generally not require a rescue.
* Test suits should aim for 100% code coverage.
* Default work values should not be considered constants. I will increase them from time to time.
* Not exposing the threads parameter is a design choice. I believe there is significant risk, and minimal gain in using a value other than '1'. Four threads on a four core box completely ties up the entire server to process one user logon. If you want more security, increase m_cost.
* Many Rubocop errors have been disabled, but any commit should avoid new alerts or demonstrate their necessity.

## Usage

Require this in your Gemfile like a typical Ruby gem:

```ruby
require 'argon2'
```

To generate a hash using specific time and memory cost:

```ruby
hasher = Argon2::Password.new(t_cost: 2, m_cost: 16)
hasher.create("password")
    => "$argon2i$v=19$m=65536,t=2,p=1$jL7lLEAjDN+pY2cG1N8D2g$iwj1ueduCvm6B9YVjBSnAHu+6mKzqGmDW745ALR38Uo"
```

To utilise default costs:

```ruby
hasher = Argon2::Password.new
hasher.create("password")
```

Alternatively, use this shotcut:

```ruby
Argon2::Password.create("password")
    => "$argon2i$v=19$m=65536,t=2,p=1$61qkSyYNbUgf3kZH3GtHRw$4CQff9AZ0lWd7uF24RKMzqEiGpzhte1Hp8SO7X8bAew"
```

You can then use this function to verify a password against a given hash. Will return either true or false.

```ruby
Argon2::Password.verify_password("password", secure_password)
```

Argon2 supports an optional key value. This should be stored securely on your server, such as alongside your database credentials. Hashes generated with a key will only validate when presented that key.

```ruby
KEY = "A key"
argon = Argon2::Password.new(t_cost: 2, m_cost: 16, secret: KEY)
myhash = argon.create("A password")
Argon2::Password.verify_password("A password", myhash, KEY)
```

## Important notes regarding version 1.0 upgrade
Version 1.0.0 included a major version bump over 0.1.4 due to several breaking changes. The first of these was an API change, which you can read the background on [here](https://github.com/technion/ruby-argon2/issues/9).

The second of these is that the reference Argon2 implementation introduced an algorithm change, which produces a hash which is not backwards compatible. This is documented on [this PR on the C library](https://github.com/P-H-C/phc-winner-argon2/pull/115). This was a regrettable requirement to address a security concern in the algorithm itself. The two versions of the Argon2 algorithm are numbered 1.0 and 1.3 respectively.

Shortly after this, version 1.0.0 of this gem was released with this breaking change, supporting only Argon2 v1.3. Further time later, the official encoding format was updated, with a spec that included the version number, and the library introduced backward compatibility. This should remove the likelyhood of such breaking changes in future. Version 1.1.0 will silently introduce the current version number in hashes, in order to avoid a further compatibility break.


## Platform Issues

The default installation workflow has caused issues with a number of gems under the latest OSX. There is some excellent documentation on the issue and some workarounds in the [Jekyll Documentation](http://jekyllrb.com/docs/troubleshooting/#jekyll-amp-mac-os-x-1011). With this in mind, OSX is a fully supported OS.

Windows is not. Nobody anywhere has the resources to support Ruby FFI code on Windows.

grsec introduces certain challenges. Please see [documentation here](https://github.com/technion/ruby-argon2/issues/15).

## RubyDocs documentation

[The usual URL](http://www.rubydoc.info/gems/argon2) will provide detailed documentation.

## FAQ
### Don't roll your own crypto!

This gets its own section because someone will raise it. I did not invent or alter this algorithm, or implement it directly. These bindings were written following [considerable involvement with the C reference](https://github.com/P-H-C/phc-winner-argon2/commits/master?author=technion), and a strong focus has been made on following the intent of the algorithm.

It is strongly advised to avoid implementations that utilise off-spec methods of introducing salts, invent imaginary parameters, or which use the word "encryption" in describing the password hashing process

### Secure wipe is useless

Although the low level C contains support for "secure memory wipe", any code hitting that layer has copied your password to a dozen places in memory. It should be assumed that such functionality does not exist.

### Work maximums may be tighter than reference

The reference implementation is aimed to provide secure hashing for many years. This implementation doesn't want you to DoS yourself in the meantime. Accordingly, some limits artificial limits exist on work powers. This gem can be much more agile in raising these as technology progresses.

### Salts in general

If you are providing your own salt, you are probably using it wrong. The design of any secure hashing system should take care of it for you.

## Contributing

Any form of contribution is appreciated, however, please review [CONTRIBUTING.md](CONTRIBUTING.md).


## Building locally/Tests

To build the gem locally, you will need to checkout the submodule and build it manually:

```shell
git submodule update --init --recursive
bundle install
cd ext/argon2_wrap/
make
cd ../..
```

The test harness includes a property based test. To more strenuously perform this test, you can tune the iterations parameter:

```shell
TEST_CHECKS=10000 bundle exec rake test
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

