# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    class Article
      module AttachmentFactory
        extend Import::Helper
        extend self

        def import(args)
          attachments   = args[:attachments] || []
          local_article = args[:local_article]

          return if skip_import?(attachments, local_article)

          perform_import(attachments, local_article)
        end

        private

        def perform_import(attachments, local_article)
          attachments.each { |attachment| import_single(local_article, attachment) }
        end

        def import_single(local_article, attachment)

          decoded_filename = Base64.decode64(attachment['Filename'])
          decoded_content  = Base64.decode64(attachment['Content'])
          # TODO: should be done by a/the Storage object
          # to handle fingerprinting
          sha = Digest::SHA256.hexdigest(decoded_content)

          retries = 3
          begin
            queueing(sha, decoded_filename)

            log "Ticket #{local_article.ticket_id}, Article #{local_article.id} - Starting import for fingerprint #{sha} (#{decoded_filename})... Queue: #{@sha_queue[sha]}."
            ActiveRecord::Base.transaction do
              Store.add(
                object:        'Ticket::Article',
                o_id:          local_article.id,
                filename:      decoded_filename.force_encoding('utf-8'),
                data:          decoded_content,
                preferences:   {
                  'Mime-Type'           => attachment['ContentType'],
                  'Content-ID'          => attachment['ContentID'],
                  'content-alternative' => attachment['ContentAlternative'],
                },
                created_by_id: 1,
              )
            end
            log "Ticket #{local_article.ticket_id}, Article #{local_article.id} - Finished import for fingerprint #{sha} (#{decoded_filename})... Queue: #{@sha_queue[sha]}."
          rescue ActiveRecord::RecordNotUnique, ActiveRecord::StatementInvalid => e
            log "Ticket #{local_article.ticket_id} - #{sha} - #{e.class}: #{e}"
            sleep rand 3
            retry if !(retries -= 1).zero?
            raise
          rescue => e
            log "Ticket #{local_article.ticket_id} - #{sha} - #{e}: #{attachment.inspect}"
            raise
          ensure
            queue_cleanup(sha)
          end
        end

        def skip_import?(attachments, local_article)
          local_attachments = local_article.attachments
          return true if local_attachments.count == attachments.count

          # get a common ground
          local_attachments.each(&:delete)
          return true if attachments.blank?

          false
        end

        def queueing(sha, decoded_filename)
          # this is (currently) needed for avoiding
          # race conditions inserting attachments with
          # the same fingerprint in the DB in concurrent threads
          @sha_queue      ||= {}
          @sha_queue[sha] ||= []

          return if !queueing_active?

          @sha_queue[sha].push(queue_id)

          while @sha_queue[sha].first != queue_id
            sleep_time = 0.25
            log "Found active import for fingerprint #{sha} (#{decoded_filename})... sleeping #{sleep_time} seconds. Queue: #{@sha_queue[sha]}."
            sleep sleep_time
          end
        end

        def queue_cleanup(sha)
          return if !queueing_active?

          @sha_queue[sha].shift
        end

        def queueing_active?
          return if !queue_id

          true
        end

        def queue_id
          Thread.current[:thread_no]
        end
      end
    end
  end
end
