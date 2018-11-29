[![Gem Version](https://badge.fury.io/rb/omniauth-microsoft-office365.svg)](https://badge.fury.io/rb/omniauth-microsoft-office365)
[![Build Status](https://travis-ci.org/murbanski/omniauth-microsoft-office365.svg?branch=master)](https://travis-ci.org/murbanski/omniauth-microsoft-office365)

# OmniAuth::MicrosoftOffice365

Office365 OAuth2 Strategy for OmniAuth.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-microsoft-office365'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-microsoft-office365

## Usage

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :microsoft_office365, ENV['OFFICE365_KEY'], ENV['OFFICE365_SECRET']
end
```
