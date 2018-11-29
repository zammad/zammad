[![Build Status](https://travis-ci.org/WinRb/autodiscover.svg?branch=master)](https://travis-ci.org/WinRb/autodiscover)

Autodiscover
============

Ruby client for Microsoft's Autodiscover Service.

The Autodiscover Service is a component of the Microsoft Exchange architecture. Autoservice clients can access the URLs and settings needed to communicate with Exchange servers, such as the URL of the endpoint to use with the Exchange Web Services (EWS) API.

This library implements Microsoft's "Autodiscover HTTP Service Protocol Specification" to discover the endpoint for an Autodiscover server that supports a specified e-mail address and Microsoft's "Autodiscover Publishing and Lookup Protocol Specification" to get URLs and settings that are required to access Web services available from Exchange servers.

Dependencies
------------

This library requires the following Gems:

* HTTPClient
* Nokogiri
* Nori

The HTTPClient Gem in turn requires the rubyntlm Gem for Negotiate/NTLM authentication.

How to Use
----------

```ruby
require 'autodiscover'

client = Autodiscover::Client.new(email: "blumbergh@initech.local", password: "tps_eq_awesome")
data = client.autodiscover

# Get the EWS endpoint
data.ews_url

# Get an Exchange Version ingestible by EWS
data.exchange_version

# Access the raw Autodiscover data in its entirety
data.response
```

Options
-------

Besides `:email` and `:password`, `Autodiscover::Client` can take a few other options as can the #autodiscover method.

Examples:

```ruby
# Use a different username than your e-mail.
client = Autodiscover::Client.new(email: "blumbergh@initech.local", password: "tps_eq_awesome", username: 'INITECH\blumbergh')

# Override the domain
client = Autodiscover::Client.new(email: "blumbergh@initech.local", password: "tps_eq_awesome", domain: "tpsreports.local")

# Set a custom connection timeout
client = Autodiscover::Client.new(email: "blumbergh@initech.local", password: "tps_eq_awesome", connect_timeout: 5)

# Ignore SSL Errors
client.autodiscover(ignore_ssl_errors: true)
```


Installation
------------

### Configuring a Rails App to use the latest GitHub master version

	  gem 'autodiscover', :git => 'git://github.com/WinRb/autodiscover.git'

### To install the latest development version from the GitHub master

	  git clone http://github.com/WinRb/autodiscover.git
	  cd autodiscover
	  gem build autodiscover.gemspec
	  sudo gem install autodiscover-<version>.gem

Bugs and Issues
---------------

Limitations:

* Doesn't support querying the DNS for SRV Records

Please submit additional bugs and issues here [http://github.com/WinRb/autodiscover/issues](http://github.com/WinRb/autodiscover/issues)
