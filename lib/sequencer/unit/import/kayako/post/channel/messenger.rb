# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Post::Channel::Messenger < Sequencer::Unit::Import::Kayako::Post::Channel::Mail
  private

  def article_type_name
    'chat'
  end
end
