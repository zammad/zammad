# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Channel < ApplicationModel
  load 'channel/assets.rb'
  include Channel::Assets

  store :options
  store :preferences

  after_create   :email_address_check
  after_update   :email_address_check
  after_destroy  :email_address_check

  # rubocop:disable Style/ClassVars
  @@channel_stream = {}
# rubocop:enable Style/ClassVars

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

  def fetch(force = false)

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
      return if !force && !driver_instance.fetchable?(self)
      result = driver_instance.fetch(adapter_options, self)
      self.status_in   = result[:result]
      self.last_log_in = result[:notice]
      preferences[:last_fetch] = Time.zone.now
      save
    rescue => e
      error = "Can't use Channel::Driver::#{adapter.to_classname}: #{e.inspect}"
      logger.error error
      logger.error e.backtrace
      self.status_in = 'error'
      self.last_log_in = error
      preferences[:last_fetch] = Time.zone.now
      save
    end

  end

=begin

stream instance of account

  channel = Channel.where(area: 'Twitter::Account').first
  stream_instance = channel.stream_instance

  # start stream
  stream_instance.stream

=end

  def stream_instance

    adapter = options[:adapter]

    begin

      # we need to require each channel backend individually otherwise we get a
      # 'warning: toplevel constant Twitter referenced by Channel::Driver::Twitter' error e.g.
      # so we have to convert the channel name to the filename via Rails String.underscore
      # http://stem.ps/rails/2015/01/25/ruby-gotcha-toplevel-constant-referenced-by.html
      require "channel/driver/#{adapter.to_filename}"

      driver_class    = Object.const_get("Channel::Driver::#{adapter.to_classname}")
      driver_instance = driver_class.new

      # check is stream exists
      return if !driver_instance.respond_to?(:stream_instance)
      driver_instance.stream_instance(self)

      # set scheduler job to active

      return driver_instance
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

stream all accounts

  Channel.stream

=end

  def self.stream
    Thread.abort_on_exception = true

    last_channels = []

    loop do
      logger.debug 'stream controll loop'
      current_channels = []
      channels = Channel.where('active = ? AND area LIKE ?', true, '%::Account')
      channels.each {|channel|
        next if channel.options[:adapter] != 'twitter'

        current_channels.push channel.id

        # exit it channel has changed
        if @@channel_stream[channel.id] && @@channel_stream[channel.id][:updated_at] != channel.updated_at
          logger.debug "channel (#{channel.id}) has changed, restart thread"
          @@channel_stream[channel.id][:thread].exit
          @@channel_stream[channel.id][:thread].join
          @@channel_stream[channel.id][:stream_instance].disconnect
          @@channel_stream[channel.id] = false
        end

        #logger.debug "thread for channel (#{channel.id}) already running" if @@channel_stream[channel.id]
        next if @@channel_stream[channel.id]

        @@channel_stream[channel.id] = {
          updated_at: channel.updated_at
        }

        # start threads for each channel
        @@channel_stream[channel.id][:thread] = Thread.new {
          begin
            logger.debug "Started stream channel for '#{channel.id}' (#{channel.area})..."
            @@channel_stream[channel.id][:stream_instance] = channel.stream_instance
            @@channel_stream[channel.id][:stream_instance].stream
            @@channel_stream[channel.id][:stream_instance].disconnect
            @@channel_stream[channel.id] = false
            logger.debug " ...stopped thread for '#{channel.id}'"
          rescue => e
            error = "Can't use channel (#{channel.id}): #{e.inspect}"
            logger.error error
            logger.error e.backtrace
            channel.status_in = 'error'
            channel.last_log_in = error
            channel.save
            @@channel_stream[channel.id] = false
          end
        }
      }

      # cleanup deleted channels
      last_channels.each {|channel_id|
        next if !@@channel_stream[channel_id]
        next if current_channels.include?(channel_id)
        logger.debug "channel (#{channel_id}) not longer active, stop thread"
        @@channel_stream[channel_id][:thread].exit
        @@channel_stream[channel_id][:thread].join
        @@channel_stream[channel_id][:stream_instance].disconnect
        @@channel_stream[channel_id] = false
      }
      last_channels = current_channels

      sleep 30
    end

  end

=begin

send via account

  channel = Channel.where(area: 'Email::Account').first
  channel.deliver(mail_params, notification)

=end

  def deliver(mail_params, notification = false)

    # ignore notifications in developer mode
    if notification == true && Setting.get('developer_mode') == true
      logger.notice "Do not send notification #{mail_params.inspect} because of enabled developer_mode"
    end

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
