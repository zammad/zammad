# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::Comment::Attachment::Request < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_action :skipped

  uses :resource, :instance
  provides :response, :action

  def process
    if response.success?
      state.provide(:response, response)
    else
      skip_attachment
    end
  end

  private

  def response
    @response ||= fetch
  end

  def fetch
    attachment_response = nil

    5.times do |iteration|
      attachment_response = UserAgent.get(
        resource.content_url,
        {},
        {
          open_timeout: 20,
          read_timeout: 240,
          verify_ssl:   true,
        },
      )

      return attachment_response if attachment_response.success?

      logger.info "Sleeping 10 seconds after attachment request error and retry (##{iteration + 1}/5)."
      sleep 10
    end

    attachment_response
  end

  def skip_attachment
    logger.error "Skipping. Error while downloading Attachment from '#{resource.content_url}': #{response.error} (ticket_id: #{instance.ticket_id}, article_id: #{instance.id})"
    state.provide(:action, :skipped)
  end
end
