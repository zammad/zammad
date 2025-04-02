# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Post::Channel::Helpcenter < Sequencer::Unit::Import::Kayako::Post::Channel::Mail
  private

  def article_type_name
    'web'
  end
end
