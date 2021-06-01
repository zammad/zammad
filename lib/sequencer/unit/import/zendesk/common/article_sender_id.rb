# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Common
          class ArticleSenderID < Sequencer::Unit::Common::Provider::Named

            uses :user_id

            private

            def article_sender_id
              return article_sender('Customer') if author.role?('Customer')
              return article_sender('Agent') if author.role?('Agent')

              article_sender('System')
            end

            def author
              @author ||= ::User.find(user_id)
            end

            def article_sender(name)
              ::Ticket::Article::Sender.select(:id).find_by(name: name).id
            end
          end
        end
      end
    end
  end
end
