# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    class ArticleCustomer
      include Import::Helper

      def initialize(article)
        import(article)
      rescue Exceptions::UnprocessableEntity
        log "ERROR: Can't extract customer from Article #{article[:id]}"
      end

      class << self

        def find(article)
          email = local_email(article['From'])
          return if !email

          user   = ::User.find_by(email: email)
          user ||= ::User.find_by(login: email)
          user
        end

        def local_email(from)
          # TODO: should get unified with User#check_email
          email = extract_email(from)
          return if !email

          email.downcase
        end

        private

        def extract_email(from)
          Mail::Address.new(from).address
        rescue
          return from if from !~ %r{<\s*([^>]+)}

          $1.strip
        end
      end

      private

      def import(article)
        find_or_create(article)
      end

      def find_or_create(article)
        return if self.class.find(article)

        create(article)
      end

      def create(article)
        email = self.class.local_email(article['From'])
        ::User.create(
          login:         email,
          firstname:     extract_display_name(article['From']),
          lastname:      '',
          email:         email,
          password:      '',
          active:        true,
          role_ids:      roles,
          updated_by_id: 1,
          created_by_id: 1,
        )
      rescue ActiveRecord::RecordNotUnique
        log "User #{email} was handled by another thread, taking this."

        return if self.class.find(article)

        log "User #{email} wasn't created sleep and retry."
        sleep rand 3
        retry
      end

      def roles
        [
          Role.find_by(name: 'Customer').id
        ]
      end

      def extract_display_name(from)
        # do extra decoding because we needed to use field.value
        Mail::Field.new('X-From', parsed_display_name(from)).to_s
      end

      def parsed_display_name(from)
        parsed_address = Mail::Address.new(from)
        return parsed_address.display_name if parsed_address.display_name
        return from if parsed_address.comments.blank?

        parsed_address.comments[0]
      rescue
        from
      end
    end
  end
end
