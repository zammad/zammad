# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Conversation::Attachments < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  optional :action

  skip_action :skipped, :failed

  uses :resource, :instance, :model_class, :dry_run

  def self.mutex
    @mutex ||= Mutex.new
  end

  def process
    return if skip?

    download_threads.each(&:join)
  end

  private

  def local_attachments
    @local_attachments ||= instance.attachments&.filter { |attachment| attachment.preferences&.dig('Content-Disposition') != 'inline' }
  end

  def skip?
    ensure_common_ground
    attachments_equal?
  end

  def ensure_common_ground
    return if attachments_equal?

    local_attachments.each(&:delete)
  end

  def attachments_equal?
    resource['attachments'].count == local_attachments.count
  end

  def download_threads
    resource['attachments'].map do |attachment|
      Thread.new do
        Thread.current.name = 'freshdesk attachment download'
        sync(attachment)
      end
    end
  end

  def sync(attachment)
    logger.debug { "Downloading attachment #{attachment}" }

    response = ::UserAgent.get(
      attachment['attachment_url'],
      {},
      {
        open_timeout: 20,
        read_timeout: 240,
        verify_ssl:   true,
      },
    )

    if !response.success?
      logger.error response.error
      return
    end

    return if dry_run

    store_attachment(attachment, response)
  end

  def store_attachment(attachment, response)
    self.class.mutex.synchronize do
      ::Store.create!(
        object:        model_class.name,
        o_id:          instance.id,
        data:          response.body,
        filename:      attachment['name'],
        preferences:   {
          'Content-Type' => attachment['content_type']
        },
        created_by_id: 1
      )
    end
  end
end
