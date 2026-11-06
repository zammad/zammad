# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Tool::CreateArticle::Preparation::Channel::Facebook < Service::AI::Tool::CreateArticle::Preparation::Channel
  delivers 'facebook feed comment', area: 'Facebook::Account', label: 'Facebook'

  # A comment answers a post as well as another comment.
  def self.replies_to?(source_type)
    ['facebook feed post', 'facebook feed comment'].include?(source_type)
  end

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  def prepare
    invalid('The Facebook channel is not configured.') if !channel.options['adapter']&.start_with?('facebook')
    page = facebook_page
    data[:in_reply_to] ||= ticket.articles.first&.message_id
    invalid('The ticket has no Facebook message to reply to.') if data[:in_reply_to].blank?
    data[:to] = data[:in_reply_to]
    data[:from] = page['name'].presence || page['id'].to_s
  end

  private

  def facebook_page
    object_id = ticket.preferences['channel_fb_object_id']
    page = Array(channel.options['pages']).find { |entry| entry['id'].to_s == object_id.to_s }
    invalid('The ticket has no configured Facebook page.') if object_id.blank? || page&.dig('access_token').blank?
    page
  end
  # rubocop:enable Zammad/DetectTranslatableString
end
