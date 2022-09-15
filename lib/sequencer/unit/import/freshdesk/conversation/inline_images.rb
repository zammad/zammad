# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module Conversation
          class InlineImages < Sequencer::Unit::Import::Common::Ticket::Article::InlineImages
            private

            def inline_image_url_prefix
              'freshdesk.com/inline/attachment'
            end
          end
        end
      end
    end
  end
end
