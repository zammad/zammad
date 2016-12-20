module Import
  module Zendesk
    class Ticket
      class Comment
        module Sender

          # rubocop:disable Style/ModuleFunction
          extend self

          def local_id(user_id)
            author = author_lookup(user_id)
            sender_id(author)
          end

          private

          def author_lookup(user_id)
            ::User.find( user_id )
          end

          def sender_id(author)
            if author.role?('Customer')
              article_sender_customer
            elsif author.role?('Agent')
              article_sender_agent
            else
              article_sender_system
            end
          end

          def article_sender_customer
            return @article_sender_customer if @article_sender_customer
            @article_sender_customer = ::Ticket::Article::Sender.lookup(name: 'Customer').id
          end

          def article_sender_agent
            return @article_sender_agent if @article_sender_agent
            @article_sender_agent = ::Ticket::Article::Sender.lookup(name: 'Agent').id
          end

          def article_sender_system
            return @article_sender_system if @article_sender_system
            @article_sender_system = ::Ticket::Article::Sender.lookup(name: 'System').id
          end
        end
      end
    end
  end
end
