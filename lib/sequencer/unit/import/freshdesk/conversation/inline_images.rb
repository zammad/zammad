# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Conversation::InlineImages < Sequencer::Unit::Import::Common::Ticket::Article::InlineImages
  private

  def inline_image_url_prefix
    'freshdesk.com/inline/attachment'
  end
end
