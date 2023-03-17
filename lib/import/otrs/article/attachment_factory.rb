# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

          # rubocop:disable Style/ClassVars
          @@mutex ||= Mutex.new
          @@mutex.synchronize do
            # rubocop:enable Style/ClassVars

            Store.create!(
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
        end

        def skip_import?(attachments, local_article)
          local_attachments = local_article.attachments
          return true if local_attachments.count == attachments.count

          # get a common ground
          local_attachments.each(&:delete)
          return true if attachments.blank?

          false
        end
      end
    end
  end
end
