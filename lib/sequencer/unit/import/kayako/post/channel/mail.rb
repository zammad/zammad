# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Post::Channel::Mail < Sequencer::Unit::Import::Kayako::Post::Channel::Base
  def mapping
    super.merge(
      to:           to,
      cc:           cc,
      body:         original_post['body_html'] || original_post['body_text'] || '',
      content_type: 'text/html',
    )
  end

  private

  def article_type_name
    'email'
  end

  def identify_key
    'email'
  end

  def from
    return super if resource['is_requester'] || original_post['mailbox'].blank?

    original_post['mailbox']['address']
  end

  def to
    recipients = build_recipients('TO')

    # Add the mailbox address to the 'TO' field if it's a requester post.
    if resource['is_requester'] && original_post['mailbox'].present?
      recipients = "#{original_post['mailbox']['address']}#{", #{recipients}" if recipients.present?}"
    end

    recipients
  end

  def cc
    build_recipients('CC')
  end

  def build_recipients(field_type)
    return if !original_post.key?('recipients') || original_post['recipients'].empty?

    original_post['recipients'].filter_map do |recipient|
      next if recipient['type'] != field_type

      recipient[identify_key]
    end.join(', ')
  end
end
