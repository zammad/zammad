# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Common
          class ArticleTypeID < Sequencer::Unit::Common::Provider::Named

            uses :resource

            private

            def article_type_id
              ::Ticket::Article::Type.select(:id).find_by(name: name).id
            end

            def name
              known_channel || 'web'
            end

            def known_channel
              channel = resource.via.channel
              direct_mapping.fetch(channel, indirect_map(channel))
            end

            def indirect_map(channel)
              method_name = :"remote_name_#{channel}"
              send(method_name) if respond_to?(method_name, true)
            end

            def remote_name_facebook
              return 'facebook feed post' if resource.via.source.rel == 'post'

              'facebook feed comment'
            end

            def remote_name_twitter
              return 'twitter status' if resource.via.source.rel == 'mention'

              'twitter direct message'
            end

            def direct_mapping
              {
                'web'           => 'web',
                'email'         => 'email',
                'sample_ticket' => 'note',
              }.freeze
            end
          end
        end
      end
    end
  end
end
