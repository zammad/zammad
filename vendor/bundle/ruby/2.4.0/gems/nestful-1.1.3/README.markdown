Nestful is a simple Ruby HTTP/REST client with a sane API.

## Installation

    sudo gem install nestful

## Features

  * Simple API
  * JSON requests
  * Resource API
  * Proxy support
  * SSL support

## API

### GET request

    Nestful.get 'http://example.com' #=> "body"

### POST request

    # url-encoded form POST
    Nestful.post 'http://example.com', :foo => 'bar'

    # JSON POST
    Nestful.post 'http://example.com', {:foo => 'bar'}, :format => :json

### Parameters

    # You can also provide nestled params
    Nestful.get 'http://example.com', :nestled => {:vars => 1}

## Request

`Request` is the base class for making HTTP requests - everthing else is just an abstraction upon it.

    Nestful::Request.new(url, options).execute #=> <Nestful::Response>

Valid `Request` options are:

  * headers (hash)
  * params  (hash)
  * method  (:get/:post/:put/:delete/:head)
  * proxy
  * user
  * password
  * auth_type (:basic/:bearer)
  * timeout
  * ssl_options

Requests are run via the `execute` method.

## Endpoint

The `Endpoint` class provides a single object to work with restful services. The following example does a GET request to the URL; http://example.com/assets/1/

    Nestful::Endpoint.new('http://example.com')['assets'][1].get #=> Nestful::Response

## Resource

If you're building a binding for a REST API, then you should consider using the `Resource` class.

    class Charge < Nestful::Resource
      endpoint 'https://api.stripe.com/v1/charges'
      options :auth_type => :bearer, :password => 'sk_bar'

      def self.all
        self.new(get)
      end

      def self.find(id)
        self.new(get(id))
      end

      def refund
        post(:refund)
      end
    end

    Charge.all #=> []
    Charge.find('ch_bar').amount

## Response

All HTTP responses are in the form of a `Nestful::Response` instance. This contains the raw HTTP response, body, headers and a few helper methods:

    response = Nestful.get('http://www.google.com')
    response.body #=> '<html>...'
    response.headers #=> {'Content-Type' => 'text/html'}
    response.status #=> 200

You can also access the decoded body if available, such as for JSON responses:

    response = Nestful.get('http://api.stripe.com/v1/charges')
    charges  = response.decoded

All calls are proxied to the decoded body, so you can access JSON properties like this:

    charges = Nestful.get('http://api.stripe.com/v1/charges')['data']

## Credits

Parts of the connection code were inspired from ActiveResource.
