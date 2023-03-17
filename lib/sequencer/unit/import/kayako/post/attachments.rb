# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Post::Attachments < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Kayako::Requester
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  optional :action

  skip_action :skipped, :failed

  uses :resource, :instance, :model_class, :dry_run

  def self.mutex
    @mutex ||= Mutex.new
  end

  def process
    return if resource['attachments'].blank?

    download_threads.each(&:join)
  end

  private

  def download_threads
    resource['attachments'].map do |attachment|
      Thread.new do
        sync(attachment)
      end
    end
  end

  def sync(attachment)
    logger.debug { "Downloading attachment #{attachment}" }

    response =  request(
      api_path: attachment['url_download'].gsub("#{Setting.get('import_kayako_endpoint')}/", ''),
    )

    return if dry_run

    store_attachment(attachment, response)
  rescue => e
    logger.error(e)
  end

  def store_attachment(attachment, response)
    self.class.mutex.synchronize do
      ::Store.create!(
        object:        model_class.name,
        o_id:          instance.id,
        data:          response.body,
        filename:      attachment['name'],
        preferences:   {
          'Content-Type' => attachment['type']
        },
        created_by_id: 1
      )
    end
  end
end
