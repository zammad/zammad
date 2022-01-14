# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module Common
          class ArticleSourceChannel < Sequencer::Unit::Common::Provider::Named

            uses :resource, :id_map

            private

            def article_source_channel
              channel = resource['source_channel']&.fetch('type')

              return if !channel

              "Sequencer::Unit::Import::Kayako::Post::Channel::#{channel.capitalize}".constantize.new(resource)
            end
          end
        end
      end
    end
  end
end
