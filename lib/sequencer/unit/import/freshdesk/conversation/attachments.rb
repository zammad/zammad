# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module Conversation
          class Attachments < Sequencer::Unit::Base
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

              response = ::UserAgent.get(
                attachment['attachment_url'],
                {},
                {
                  open_timeout: 20,
                  read_timeout: 240,
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
                ::Store.add(
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
        end
      end
    end
  end
end
