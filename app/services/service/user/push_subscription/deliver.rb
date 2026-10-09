# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Sends a message to one subscribed device. Raises TemporaryError only for
#   failures a later attempt may not hit again; every other failure is
#   settled here.
class Service::User::PushSubscription::Deliver < Service::Base
  TTL = 1.day.to_i

  class TemporaryError < StandardError; end
  class ProxyConfigurationError < StandardError; end

  TEMPORARY_ERRORS = [
    WebPush::PushServiceError, WebPush::TooManyRequests,
    SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError
  ].freeze

  # Only these say the subscription itself is gone, e.g. the browser unsubscribed.
  SUBSCRIPTION_GONE_ERRORS = [WebPush::ExpiredSubscription, WebPush::InvalidSubscription].freeze

  # Rejected signatures, VAPID keys or the proxy fail for every device alike
  #   and on every attempt, so the subscriptions are kept until the
  #   configuration is fixed.
  CONFIGURATION_ERRORS = [
    WebPush::Error, ProxyConfigurationError, ArgumentError, URI::Error,
    OpenSSL::PKey::PKeyError, OpenSSL::PKey::EC::Point::Error
  ].freeze

  attr_reader :subscription, :message

  def initialize(subscription:, message:)
    @subscription = subscription
    @message      = message
  end

  def execute
    # Stored subscriptions are not validated again when a later version drops a
    #   push service from PushSubscription::PUSH_SERVICE_DOMAINS.
    return remove_subscription('unknown push service') if !subscription.known_push_service?

    send_message
  rescue *TEMPORARY_ERRORS => e
    raise TemporaryError, "#{e.class.name}: #{e.message}"
  rescue *SUBSCRIPTION_GONE_ERRORS => e
    remove_subscription(e.class.name)
  rescue *CONFIGURATION_ERRORS => e
    Rails.logger.error { "Web push to subscription #{subscription.id} failed (#{e.class.name}): #{e.message}" }
  end

  private

  def send_message
    WebPush.payload_send(
      message:,
      endpoint:     subscription.endpoint,
      p256dh:       subscription.p256dh,
      auth:         subscription.auth,
      vapid:        vapid_options,
      ttl:          TTL,
      open_timeout: 5,
      read_timeout: 10,
      ssl_timeout:  5,
      **proxy_options,
    )
  end

  def remove_subscription(reason)
    Rails.logger.info { "Removing web push subscription #{subscription.id} (#{reason})." }
    subscription.destroy
  end

  # RFC 8292 only allows https or mailto subjects.
  def vapid_options
    {
      subject:     "https://#{Setting.get('fqdn')}",
      public_key:  Setting.get('web_push_vapid_public_key'),
      private_key: Setting.get('web_push_vapid_private_key'),
    }
  end

  # web-push builds its own Net::HTTP and only takes a proxy URL, so the
  #   proxy configuration is resolved through the same code path as every
  #   other outgoing request, including the no-proxy list.
  def proxy_options
    client = http_client
    return {} if !client.proxy_class?

    userinfo = [client.proxy_user, client.proxy_pass]
      .compact_blank
      .map { URI.encode_www_form_component(it) }
      .join(':')

    { proxy: URI::Generic.build(scheme: 'http', userinfo: userinfo.presence, host: client.proxy_address, port: client.proxy_port).to_s }
  end

  # A proxy address without port is reported as a plain RuntimeError.
  def http_client
    UserAgent::HttpClient.get_client(URI.parse(subscription.endpoint), {})
  rescue RuntimeError => e
    raise ProxyConfigurationError, e.message
  end
end
