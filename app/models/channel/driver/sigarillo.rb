# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/

class Channel::Driver::Sigarillo

=begin

  Channel::Driver::Sigarillo.fetchable?

returns

  true|false

=end
  def fetchable?(_channel)
    Rails.logger.debug { 'sigarillo fetchable? YES!' }
    return true if Rails.env.test?

    # only fetch once in 30 minutes
    # return true if !channel.preferences
    # return true if !channel.preferences[:last_fetch]
    # return false if channel.preferences[:last_fetch] > Time.zone.now - 20.minutes

    true
  end

=begin

fetch messages from signal

  options = {}

  instance = Channel::Driver::Sigarillo.new
  result = instance.fetch(options, channel)

returns

  {
    result: 'ok',
  }

=end
  def fetch(options, channel)
    Rails.logger.debug { 'sigarillo fetch called' }

    options = check_external_credential(options)
    @sigarillo = ::Sigarillo.new(channel.options[:api_url], channel.options[:api_token])

    Rails.logger.debug { 'sigarillo fetch started' }
    @sigarillo.fetch_messages(channel.group_id, channel)
    Rails.logger.debug { 'sigarillo fetch completed' }
    {
      result: 'ok',
      notice: '',
    }
  end

  def disconnect; end

=begin

  instance = Channel::Driver::Sigarillo.new
  instance.send(
    {
      adapter: 'signal',
      auth: {
        api_key:       api_key
      },
    },
    signal_attributes,
    notification
  )

=end

  def send(options, article, _notification = false)
    # return if we run import mode
    return if Setting.get('import_mode')

    options = check_external_credential(options)

    Rails.logger.debug { 'sigarillo send started' }
    Rails.logger.debug { options.inspect }
    @sigarillo = ::Sigarillo.new(options[:api_url], options[:api_token])
    @sigarillo.from_article(article)
  end

=begin

  Channel::Driver::Sigarillo.streamable?

returns

  true|false

=end

  def self.streamable?
    false
  end

  private

  def check_external_credential(options)
    if options[:auth] && options[:auth][:external_credential_id]
      external_credential = ExternalCredential.find_by(id: options[:auth][:external_credential_id])
      raise "No such ExternalCredential.find(#{options[:auth][:external_credential_id]})" if !external_credential

      options[:auth][:api_key] = external_credential.credentials['api_key']
    end
    options
  end

end
