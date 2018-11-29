# Clearbit

A Ruby API client to [https://clearbit.com](https://clearbit.com).

## Installation

Add this line to your application's Gemfile:

``` ruby
gem 'clearbit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install clearbit

## Usage

First authorize requests by setting the API key found on your [account's settings page](https://clearbit.com/keys).

``` ruby
Clearbit.key = ENV['CLEARBIT_KEY']
```

Then you can lookup people by email address:

``` ruby
result = Clearbit::Enrichment.find(email: 'alex@alexmaccaw.com', stream: true)

person  = result.person
company = result.company
```

Passing the `stream` option makes the operation blocking - it could hang for 4-5 seconds if we haven't seen the email before. Alternatively you can use our [webhook](https://clearbit.com/docs#webhooks) API. If a person or company can't be found, then they'll be `nil`.

See the [documentation](https://clearbit.com/docs#person-api) for more information.

## Company lookup

You can lookup company data by domain name:

``` ruby
company = Clearbit::Enrichment::Company.find(domain: 'uber.com', stream: true)
```

If the company can't be found, then `nil` will be returned.

See the [documentation](https://clearbit.com/docs#company-api) for more information.

## Other APIs

For more info on our other APIs (such as the Watchlist or Discover APIs), please see our [main documentation](https://clearbit.com/docs).

## Webhooks

For rack apps use the `Clearbit::Webhook` module to wrap deserialization and verify the webhook is from trusted party:

``` ruby
post '/v1/webhooks/clearbit' do
  begin
    webhook = Clearbit::Webhook.new(env)
    webhook.type #=> 'person'
    webhook.body.name.given_name #=> 'Alex'

    # ...
  rescue Clearbit::Errors::InvalidWebhookSignature => e
    # ...
  end
end
```

The global Clearbit.key can be overriden for multi-tenant apps using multiple Clearbit keys like so:

```ruby
webhook = Clearbit::Webhook.new(env, 'CLEARBIT_KEY')
```
