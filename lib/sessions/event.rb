# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event
  include ApplicationLib

  # Event names are supplied by the client, so only plain snake_case names are
  # accepted before they are used to resolve a handler class.
  EVENT_NAME_REGEX = %r{\A[a-z][a-z0-9_]*\z}

  def self.run(event:, payload: nil, session: nil, headers: nil, client_id: nil, client: nil, options: {})
    backend = backend_for(event)
    if !backend
      Rails.logger.error { "No such event #{event.inspect.truncate(100)}." }
      return generic_error(payload)
    end

    begin
      instance = backend.new(event:, payload:, session:, headers:, client_id:, client:, options:)

      # The instance must release its database connection also when the event fails.
      begin
        instance.run
      ensure
        instance.destroy
      end
    rescue => e
      Rails.logger.error { "Event '#{event}' failed: #{e.inspect}" }
      Rails.logger.error e.backtrace
      generic_error(payload)
    end
  ensure
    UserInfo.reset
    ActiveSupport::CurrentAttributes.clear_all
  end

  # Resolves the event handler class for a client supplied event name.
  # Returns nil for anything that is not a concrete, runnable event handler.
  def self.backend_for(event)
    return if !event.is_a?(String)
    return if !event.match?(EVENT_NAME_REGEX)

    backend = "Sessions::Event::#{event.to_classname}".safe_constantize

    return if !backend.is_a?(Class)
    return if !(backend <= Sessions::Event::Base)
    return if backend.abstract_event?
    return if !backend.method_defined?(:run)

    backend
  # Loading the handler class may fail for reasons safe_constantize re-raises,
  # which must not reach the caller either.
  rescue StandardError, LoadError => e
    Rails.logger.error { "Event #{event.inspect.truncate(100)} could not be resolved: #{e.inspect}" }
    Rails.logger.error e.backtrace
    nil
  end
  private_class_method :backend_for

  # Errors must not leak any internal state to the client, the details are
  # available in the server side log only.
  def self.generic_error(payload)
    {
      event: 'error',
      data:  {
        error:   __('The event could not be processed.'),
        payload: payload,
      },
    }
  end
  private_class_method :generic_error
end
