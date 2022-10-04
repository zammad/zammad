# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::Comment::InlineImages < Sequencer::Unit::Import::Common::Ticket::Article::InlineImages
  private

  def inline_image_url_prefix
    'zendesk.com/attachments'
  end
end
