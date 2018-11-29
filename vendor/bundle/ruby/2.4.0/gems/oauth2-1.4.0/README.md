# OAuth2

[![Gem Version](http://img.shields.io/gem/v/oauth2.svg)][gem]
[![Build Status](http://img.shields.io/travis/intridea/oauth2.svg)][travis]
[![Dependency Status](http://img.shields.io/gemnasium/intridea/oauth2.svg)][gemnasium]
[![Code Climate](http://img.shields.io/codeclimate/github/intridea/oauth2.svg)][codeclimate]
[![Coverage Status](http://img.shields.io/coveralls/intridea/oauth2.svg)][coveralls]

[gem]: https://rubygems.org/gems/oauth2
[travis]: http://travis-ci.org/intridea/oauth2
[gemnasium]: https://gemnasium.com/intridea/oauth2
[codeclimate]: https://codeclimate.com/github/intridea/oauth2
[coveralls]: https://coveralls.io/r/intridea/oauth2

A Ruby wrapper for the OAuth 2.0 specification.

## Installation
    gem install oauth2

## Resources
* [View Source on GitHub][code]
* [Report Issues on GitHub][issues]
* [Read More at the Wiki][wiki]

[code]: https://github.com/intridea/oauth2
[issues]: https://github.com/intridea/oauth2/issues
[wiki]: https://wiki.github.com/intridea/oauth2

## Usage Examples

```ruby
require 'oauth2'
client = OAuth2::Client.new('client_id', 'client_secret', :site => 'https://example.org')

client.auth_code.authorize_url(:redirect_uri => 'http://localhost:8080/oauth2/callback')
# => "https://example.org/oauth/authorization?response_type=code&client_id=client_id&redirect_uri=http://localhost:8080/oauth2/callback"

token = client.auth_code.get_token('authorization_code_value', :redirect_uri => 'http://localhost:8080/oauth2/callback', :headers => {'Authorization' => 'Basic some_password'})
response = token.get('/api/resource', :params => { 'query_foo' => 'bar' })
response.class.name
# => OAuth2::Response
```
## OAuth2::Response
The AccessToken methods #get, #post, #put and #delete and the generic #request
will return an instance of the #OAuth2::Response class.

This instance contains a #parsed method that will parse the response body and
return a Hash if the Content-Type is application/x-www-form-urlencoded or if
the body is a JSON object.  It will return an Array if the body is a JSON
array.  Otherwise, it will return the original body string.

The original response body, headers, and status can be accessed via their
respective methods.

## OAuth2::AccessToken
If you have an existing Access Token for a user, you can initialize an instance
using various class methods including the standard new, from_hash (if you have
a hash of the values), or from_kvform (if you have an
application/x-www-form-urlencoded encoded string of the values).

## OAuth2::Error
On 400+ status code responses, an OAuth2::Error will be raised.  If it is a
standard OAuth2 error response, the body will be parsed and #code and #description will contain the values provided from the error and
error_description parameters.  The #response property of OAuth2::Error will
always contain the OAuth2::Response instance.

If you do not want an error to be raised, you may use :raise_errors => false
option on initialization of the client.  In this case the OAuth2::Response
instance will be returned as usual and on 400+ status code responses, the
Response instance will contain the OAuth2::Error instance.

## Authorization Grants
Currently the Authorization Code, Implicit, Resource Owner Password Credentials, Client Credentials, and Assertion
authentication grant types have helper strategy classes that simplify client
use.  They are available via the #auth_code, #implicit, #password, #client_credentials, and #assertion methods respectively.

```ruby
auth_url = client.auth_code.authorize_url(:redirect_uri => 'http://localhost:8080/oauth/callback')
token = client.auth_code.get_token('code_value', :redirect_uri => 'http://localhost:8080/oauth/callback')

auth_url = client.implicit.authorize_url(:redirect_uri => 'http://localhost:8080/oauth/callback')
# get the token params in the callback and
token = OAuth2::AccessToken.from_kvform(client, query_string)

token = client.password.get_token('username', 'password')

token = client.client_credentials.get_token

token = client.assertion.get_token(assertion_params)
```

If you want to specify additional headers to be sent out with the
request, add a 'headers' hash under 'params':

```ruby
token = client.auth_code.get_token('code_value', :redirect_uri => 'http://localhost:8080/oauth/callback', :headers => {'Some' => 'Header'})
```

You can always use the #request method on the OAuth2::Client instance to make
requests for tokens for any Authentication grant type.

## Supported Ruby Versions
This library aims to support and is [tested against][travis] the following Ruby
implementations:

* Ruby 1.9.3
* Ruby 2.0.0
* Ruby 2.1
* Ruby 2.2
* Ruby 2.3
* Ruby 2.4
* [JRuby 9K][jruby]

[jruby]: http://jruby.org/

If something doesn't work on one of these interpreters, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby
implementations, however support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be responsible for providing patches in a timely
fashion. If critical issues for a particular implementation exist at the time
of a major release, support for that Ruby version may be dropped.

## License
Copyright (c) 2011-2013 Michael Bleigh and Intridea, Inc. See [LICENSE][] for
details.

[license]: LICENSE.md
