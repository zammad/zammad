# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Post::InlineImages < Sequencer::Unit::Import::Common::Ticket::Article::InlineImages
  private

  def inline_image_url_prefix
    'kayako.com/media/url'
  end
end
