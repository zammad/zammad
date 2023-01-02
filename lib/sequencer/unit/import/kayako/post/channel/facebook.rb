# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Post::Channel::Facebook < Sequencer::Unit::Import::Kayako::Post::Channel::Base
  def mapping
    super.merge(
      message_id: original_post['id'],
      to:         to,
      body:       original_post['contents'],
    )
  end

  private

  def article_type_name
    return 'facebook direct-message' if original_post['resource_type'] == 'facebook_message'
    return 'facebook feed comment' if original_post['resource_type'] == 'facebook_post_comment'

    'facebook feed post'
  end

  def identify_key
    'facebook_id'
  end

  def to
    return if original_post['recipient'].nil?

    original_post['recipient'][identify_key]
  end
end
