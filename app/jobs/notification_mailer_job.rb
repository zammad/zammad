# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Delivers a NotificationFactory::Mailer notification for a token based mail in the background
# instead of inside the request that triggered it. Rendering the mail and handing it over to the
# SMTP server takes as long as the remote side needs, which does not belong in a request that only
# has to acknowledge the input.
#
# The link is assembled here rather than by the caller, so that the assembled link is not part of
# the job arguments, which the `delayed_job` adapter persists. `url_path` is the part between the
# FQDN and the token, which differs per mail and per interface.
class NotificationMailerJob < ApplicationJob

  retry_on StandardError, attempts: 4, wait: lambda { |executions|
    executions * 25.seconds
  }

  # The user or one of the objects (e.g. a token) can be removed before the job runs, most likely
  # because a newer request superseded it. There is nothing left to deliver then.
  discard_on(ActiveJob::DeserializationError) do |_job, e|
    Rails.logger.info 'User or notification objects got removed before NotificationMailerJob could be executed. Discarding job. See exception for further details.'
    Rails.logger.info e
  end

  def perform(template:, user:, objects:, url_path:)
    NotificationFactory::Mailer.notification(
      template: template,
      user:     user,
      objects:  objects.merge(url: url(url_path, objects[:token])),
    )
  end

  private

  def url(url_path, token)
    "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#{url_path}#{token.token}"
  end
end
