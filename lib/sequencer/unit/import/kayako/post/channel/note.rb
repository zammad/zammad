# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Post::Channel::Note < Sequencer::Unit::Import::Kayako::Post::Channel::Base
  def mapping
    super.merge(
      body:         original_post['body_html'] || original_post['body_text'] || '',
      content_type: 'text/html',
    )
  end

  private

  def identify_key
    'email'
  end

  def article_type_name
    'note'
  end

  def internal?
    true
  end
end
