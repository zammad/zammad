require 'nestful'
require 'clearbit/version'

module Clearbit
  def self.api_key=(value)
    Base.key = value
  end

  def self.key=(value)
    Base.key = value
  end

  def self.key
    Base.key
  end

  def self.key!
    key || raise('Clearbit.key not set')
  end

  autoload :Autocomplete, 'clearbit/autocomplete'
  autoload :Base, 'clearbit/base'
  autoload :Discovery, 'clearbit/discovery'
  autoload :Enrichment, 'clearbit/enrichment'
  autoload :Logo, 'clearbit/logo'
  autoload :Mash, 'clearbit/mash'
  autoload :NameDomain, 'clearbit/name_domain'
  autoload :Pending, 'clearbit/pending'
  autoload :Prospector, 'clearbit/prospector'
  autoload :Resource, 'clearbit/resource'
  autoload :Reveal, 'clearbit/reveal'
  autoload :Risk, 'clearbit/risk'
  autoload :Watchlist, 'clearbit/watchlist'
  autoload :Webhook, 'clearbit/webhook'

  module Errors
    autoload :InvalidWebhookSignature, 'clearbit/errors/invalid_webhook_signature'
  end

  if clearbit_key = ENV['CLEARBIT_KEY']
    Clearbit.key = clearbit_key
  end

  # Backwards compatibility
  Person  = Enrichment::Person
  Company = Enrichment::Company
end
