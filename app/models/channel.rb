# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Channel < ApplicationModel
  include Channel::Assets
  include Channel::Area::Whatsapp

  belongs_to :group, optional: true

  store :options
  store :preferences

  scope :active, -> { where(active: true) }
  scope :in_area, ->(area) { where(area: area) }

  validates_with Validations::ChannelEmailAccountUniquenessValidator

  after_create   :email_address_check
  after_update   :email_address_check
  after_destroy  :email_address_check

  # rubocop:disable Style/ClassVars
  @@channel_stream = {}
  @@channel_stream_started_till_at = {}
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

    refresh_xoauth2!

    driver_class    = self.class.driver_class(adapter)
    driver_instance = driver_class.new
    return if !force && !driver_instance.fetchable?(self)

    result = driver_instance.fetch(adapter_options, self)
    self.status_in   = result[:result]
    self.last_log_in = result[:notice]
    preferences[:last_fetch] = Time.zone.now
    save!
    true
  rescue => e
    mark_as_error(e, adapter)

    preferences[:last_fetch] = Time.zone.now
    save!
    false
  end

=begin

send via account

  channel = Channel.where(area: 'Email::Account').first
  channel.deliver(params, notification)

=end

  def deliver(params, notification = false)
    adapter         = options[:adapter]
    adapter_options = options
    if options[:outbound] && options[:outbound][:adapter]
      adapter         = options[:outbound][:adapter]
      adapter_options = options[:outbound][:options]
    end

    refresh_xoauth2!

    driver_class    = self.class.driver_class(adapter)
    driver_instance = driver_class.new
    result = driver_instance.deliver(adapter_options, params, notification)
    self.status_out   = 'ok'
    self.last_log_out = ''
    save!

    result
  rescue => e
    handle_delivery_error!(e, adapter)
  end

  def handle_delivery_error!(error, adapter)
    if error.respond_to?(:retryable?) && error.retryable?
      self.status_out = 'ok'
      self.last_log_out = ''
    else
      mark_as_error(error, adapter, direction: :out)
    end

    save!

    raise DeliveryError.new(mark_as_error_message(adapter, error), error)
  end

=begin

process via account

  channel = Channel.where(area: 'Email::Account').first
  channel.process(params)

=end

  def process(params)
    adapter         = options[:adapter]
    adapter_options = options
    if options[:inbound] && options[:inbound][:adapter]
      adapter         = options[:inbound][:adapter]
      adapter_options = options[:inbound][:options]
    end
    result = nil
    begin
      driver_class    = self.class.driver_class(adapter)
      driver_instance = driver_class.new
      result = driver_instance.process(adapter_options, params, self)
      self.status_in   = 'ok'
      self.last_log_in = ''
      save!
    rescue => e
      message = mark_as_error(e, adapter)
      save!
      raise e, message
    end
    result
  end

=begin

load channel driver and return class

  klass = Channel.driver_class('Imap')

=end

  def self.driver_class(adapter)
    "::Channel::Driver::#{adapter.to_classname}".constantize
  end

=begin

get instance of channel driver

  channel.driver_instance

=end

  def driver_instance
    self.class.driver_class(options[:adapter])
  end

  def refresh_xoauth2!(force: false)
    return if options.dig(:auth, :type) != 'XOAUTH2'
    return if !force && ApplicationHandleInfo.current == 'application_server'

    result = ExternalCredential.refresh_token(options[:auth][:provider], options[:auth])

    options[:auth]                          = result
    options[:inbound][:options][:password]  = result[:access_token] if options[:inbound].present?
    options[:outbound][:options][:password] = result[:access_token]

    return if new_record?

    save!
  rescue => e
    logger.error e
    raise "Failed to refresh XOAUTH2 access_token of provider '#{options[:auth][:provider]}': #{e.message}"
  end

  # Marks the channel as experiencing issues
  # Also writes a log entry with the error message
  #
  # @param adapter [Class, nil] The adapter class
  # @param error [Exception, nil] The error that occured
  # @param message [String, nil] Optional custom error message
  # @param direction [Symbol] The direction of communication when the error occured, either :in or :out
  def mark_as_error(error, adapter, message: nil, direction: :in)
    message ||= mark_as_error_message(adapter, error)

    logger.error message
    logger.error error

    self["status_#{direction}"] = 'error'
    self["last_log_#{direction}"] = message

    message
  end

  private

  def email_address_check

    # reset non existing channel_ids
    EmailAddress.channel_cleanup
  end

  def mark_as_error_message(adapter, e)
    "#{adapter.to_classname}: #{e.message} (#{e.class})"
  end

  class DeliveryError < StandardError
    attr_reader :original_error

    def initialize(message, original_error)
      super(message)

      @original_error = original_error
    end

    def retryable?
      return true if !original_error.respond_to?(:retryable?)

      original_error.retryable?
    end
  end
end
