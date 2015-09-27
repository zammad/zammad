# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Channel < ApplicationModel
  load 'channel/assets.rb'
  include Channel::Assets

  store :options
  store :preferences

  after_create   :email_address_check
  after_update   :email_address_check
  after_destroy  :email_address_check

=begin

fetch all accounts

  Channel.fetch

=end

  def self.fetch
    channels = Channel.where('active = ? AND area LIKE ?', true, '%::Account')
    channels.each(&:fetch)
  end

=begin

fetch one account

  channel = Channel.where(area: 'Email::Account').first
  channel.fetch

=end

  def fetch

    adapter         = options[:adapter]
    adapter_options = options
    if options[:inbound] && options[:inbound][:adapter]
      adapter         = options[:inbound][:adapter]
      adapter_options = options[:inbound][:options]
    end

    begin

      # we need to require each channel backend individually otherwise we get a
      # 'warning: toplevel constant Twitter referenced by Channel::Driver::Twitter' error e.g.
      # so we have to convert the channel name to the filename via Rails String.underscore
      # http://stem.ps/rails/2015/01/25/ruby-gotcha-toplevel-constant-referenced-by.html
      require "channel/driver/#{adapter.to_filename}"

      driver_class    = Object.const_get("Channel::Driver::#{adapter.to_classname}")
      driver_instance = driver_class.new
      result = driver_instance.fetch(adapter_options, self)
      self.status_in   = result[:result]
      self.last_log_in = result[:notice]
      save
    rescue => e
      error = "Can't use Channel::Driver::#{adapter.to_classname}: #{e.inspect}"
      logger.error error
      logger.error e.backtrace
      self.status_in = 'error'
      self.last_log_in = error
      save
    end

  end

=begin

send via account

  channel = Channel.where(area: 'Email::Account').first
  channel.deliver(mail_params, notification)

=end

  def deliver(mail_params, notification = false)

    adapter         = options[:adapter]
    adapter_options = options
    if options[:outbound] && options[:outbound][:adapter]
      adapter         = options[:outbound][:adapter]
      adapter_options = options[:outbound][:options]
    end

    result = nil

    begin

      # we need to require each channel backend individually otherwise we get a
      # 'warning: toplevel constant Twitter referenced by Channel::Driver::Twitter' error e.g.
      # so we have to convert the channel name to the filename via Rails String.underscore
      # http://stem.ps/rails/2015/01/25/ruby-gotcha-toplevel-constant-referenced-by.html
      require "channel/driver/#{adapter.to_filename}"

      driver_class    = Object.const_get("Channel::Driver::#{adapter.to_classname}")
      driver_instance = driver_class.new
      result = driver_instance.send(adapter_options, mail_params, notification)
      self.status_out   = 'ok'
      self.last_log_out = ''
      save
    rescue => e
      error = "Can't use Channel::Driver::#{adapter.to_classname}: #{e.inspect}"
      logger.error error
      logger.error e.backtrace
      self.status_out = 'error'
      self.last_log_out = error
      save
    end
    result
  end

  private

  def email_address_check

    # reset non existing channel_ids
    EmailAddress.channel_cleanup
  end

end
