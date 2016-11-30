module Import
  module OTRS
    class ArticleCustomer
      include Import::Helper

      def initialize(article)
        user = import(article)
        return if !user
        article['created_by_id'] = user.id
      rescue Exceptions::UnprocessableEntity => e
        log "ERROR: Can't extract customer from Article #{article[:id]}"
      end

      private

      def import(article)
        find_user_or_create(article)
      end

      def extract_email(from)
        Mail::Address.new(from).address
      rescue
        return from if from !~ /<\s*([^\s]+)/
        $1
      end

      def find_user_or_create(article)
        user = user_found?(article)
        return user if user
        create_user(article)
      end

      def user_found?(article)
        email = extract_email(article['From'])
        user   = ::User.find_by(email: email)
        user ||= ::User.find_by(login: email)
        user
      end

      def create_user(article)
        email = extract_email(article['From'])
        ::User.create(
          login:         email,
          firstname:     extract_display_name(article['from']),
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

        return if user_found?(article)

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
        return from if parsed_address.comments.empty?
        parsed_address.comments[0]
      rescue
        from
      end
    end
  end
end
