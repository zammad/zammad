# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Channel::Driver::Facebook

=begin

  instance = Channel::Driver::Facebook.new
  instance.fetch(channel.options, channel)

=end

  def fetch(options, channel)
    @channel  = channel
    @sync     = options['sync']
    @pages    = options['pages']

    Rails.logger.debug { 'facebook fetch started' }

    fetch_feed
    disconnect

    Rails.logger.debug { 'facebook fetch completed' }
    notice = ''
    {
      result: 'ok',
      notice: notice,
    }
  end

  def send(options, fb_object_id, article, _notification = false)
    access_token = nil
    options['pages'].each do |page|
      next if page['id'].to_s != fb_object_id.to_s

      access_token = page['access_token']
    end
    if !access_token
      raise "No access_token found for fb_object_id: #{fb_object_id}"
    end

    client = ::Facebook.new(access_token)
    client.from_article(article)
  end

=begin

  instance = Channel::Driver::Facebook.new
  instance.fetchable?(channel)

=end

  def fetchable?(channel)
    return true if Rails.env.test?

    # because of new page rate limit - https://developers.facebook.com/blog/post/2016/06/16/page-level-rate-limits/
    # only fetch once in 5 minutes
    return true if !channel.preferences
    return true if !channel.preferences[:last_fetch]
    return false if channel.preferences[:last_fetch] > Time.zone.now - 5.minutes

    true
  end

  def disconnect; end

=begin

  Channel::Driver::Facebook.streamable?

returns

  true|false

=end

  def self.streamable?
    false
  end

  private

  def get_page(page_id)
    @pages.each do |page|
      return page if page['id'].to_s == page_id.to_s
    end
    nil
  end

  def fetch_feed
    return if !@sync
    return if !@sync['pages']

    older_import = 0
    older_import_max = 12

    @sync['pages'].each do |page_to_sync_id, page_to_sync_params|
      page = get_page(page_to_sync_id)
      next if !page
      next if page_to_sync_params['group_id'].blank?

      page_client = ::Facebook.new(page['access_token'])

      posts = page_client.client.get_connection('me', 'feed', fields: 'id,from,to,message,created_time,permalink_url,comments{id,from,to,message,created_time}')
      posts.each do |post|

        # ignore older messages
        if (@channel.created_at - 15.days) > Time.zone.parse(post['created_time']) || older_import >= older_import_max
          older_import += 1
          Rails.logger.debug { "post to old: #{post['id']}/#{post['created_time']}" }
          next
        end

        page_client.to_group(post, page_to_sync_params['group_id'], @channel, page)
      end
    end

    true
  end

end
