# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    class Article
      include Import::Helper
      include Import::OTRS::Helper

      MAPPING = {
        TicketID:    :ticket_id,
        ArticleID:   :id,
        Body:        :body,
        From:        :from,
        To:          :to,
        Cc:          :cc,
        Subject:     :subject,
        InReplyTo:   :in_reply_to,
        MessageID:   :message_id,
        #ReplyTo:    :reply_to,
        References:  :references,
        ContentType: :content_type,
        Changed:     :updated_at,
        Created:     :created_at,
        ChangedBy:   :updated_by_id,
        CreatedBy:   :created_by_id,
      }.freeze

      def initialize(article)
        initialize_article_sender_types
        initialize_article_types

        utf8_encode(article)
        import(article)
      end

      private

      def import(article)
        create_or_update(map(article))

        return if article['Attachments'].blank?

        Import::OTRS::Article::AttachmentFactory.import(
          attachments:   article['Attachments'],
          local_article: @local_article
        )
      end

      def create_or_update(article)
        return if updated?(article)

        create(article)
      end

      def updated?(article)
        @local_article = ::Ticket::Article.find_by(id: article[:id])
        return false if !@local_article

        log "update Ticket::Article.find_by(id: #{article[:id]})"
        @local_article.update!(article)
        true
      end

      def create(article)
        log "add Ticket::Article.find_by(id: #{article[:id]})"
        @local_article    = ::Ticket::Article.new(article)
        @local_article.id = article[:id]
        @local_article.save
        reset_primary_key_sequence('ticket_articles')
      rescue ActiveRecord::RecordNotUnique
        log "Ticket #{article[:ticket_id]} (article #{article[:id]}) is handled by another thead, skipping."
      end

      def map(article)
        mapped = map_default(article)
        map_content_type(mapped)
        mapped[:body] ||= ''
        mapped
      end

      def map_default(article)
        {
          created_by_id: 1,
          updated_by_id: 1,
        }
          .merge(from_mapping(article))
          .merge(article_type(article))
          .merge(article_sender_type(article))
      end

      def map_content_type(mapped)
        # if no content type is set make sure to remove it
        # so Zammad can set the default content type
        mapped.delete(:content_type) if mapped[:content_type].blank?
        return mapped if !mapped[:content_type]

        mapped[:content_type].sub!(%r{[;,]\s?.+?$}, '')
        mapped
      end

      def article_type(article)
        @article_types[article['ArticleType']] || @article_types['note-internal']
      end

      def article_sender_type(article)
        {
          sender_id: @sender_type_id[article['SenderType']] || @sender_type_id['note-internal']
        }
      end

      def initialize_article_sender_types
        @sender_type_id = {
          'customer' => article_sender_type_id_lookup('Customer'),
          'agent'    => article_sender_type_id_lookup('Agent'),
          'system'   => article_sender_type_id_lookup('System'),
        }
      end

      def article_sender_type_id_lookup(name)
        ::Ticket::Article::Sender.find_by(name: name).id
      end

      def initialize_article_types
        @article_types = {
          'email-external' => {
            type_id:  article_type_id_lookup('email'),
            internal: false
          },
          'email-internal' => {
            type_id:  article_type_id_lookup('email'),
            internal: true
          },
          'note-external'  => {
            type_id:  article_type_id_lookup('note'),
            internal: false
          },
          'note-internal'  => {
            type_id:  article_type_id_lookup('note'),
            internal: true
          },
          'phone'          => {
            type_id:  article_type_id_lookup('phone'),
            internal: false
          },
          'webrequest'     => {
            type_id:  article_type_id_lookup('web'),
            internal: false
          },
        }
      end

      def article_type_id_lookup(name)
        ::Ticket::Article::Type.lookup(name: name).id
      end
    end
  end
end
