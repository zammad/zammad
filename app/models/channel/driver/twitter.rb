# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/

class Channel::Driver::Twitter

  def fetch (_adapter_options, channel)

    @channel = channel
    @tweet   = Tweet.new(@channel[:options][:auth])
    @sync    = @channel[:options][:sync]

    Rails.logger.debug 'twitter fetch started'

    fetch_search
    fetch_mentions
    fetch_direct_messages

    disconnect

    Rails.logger.debug 'twitter fetch completed'
  end

  def send(article, _notification = false)

    @channel = Channel.find_by(area: 'Twitter::Account', active: true)
    @tweet   = Tweet.new(@channel[:options][:auth])

    tweet = @tweet.from_article(article)
    disconnect

    tweet
  end

  def disconnect
    @tweet.disconnect
  end

  private

  def fetch_search

    return if !@sync[:search]
    return if @sync[:search].empty?

    # search results
    @sync[:search].each { |search|

      result_type = search[:type] || 'mixed'

      Rails.logger.debug " - searching for '#{search[:term]}'"

      counter = 0
      @tweet.client.search(search[:term], result_type: result_type).collect { |tweet|

        break if search[:limit] && search[:limit] <= counter
        break if Ticket::Article.find_by(message_id: tweet.id)

        @tweet.to_group(tweet, search[:group_id])

        counter += 1
      }
    }
  end

  def fetch_mentions

    return if !@sync[:mentions]
    return if @sync[:mentions].empty?

    Rails.logger.debug ' - searching for mentions'

    counter = 0
    @tweet.client.mentions_timeline.each { |tweet|

      break if @sync[:mentions][:limit] && @sync[:mentions][:limit] <= counter
      break if Ticket::Article.find_by(message_id: tweet.id)

      @tweet.to_group(tweet, @sync[:mentions][:group_id])

      counter += 1
    }
  end

  def fetch_direct_messages

    return if !@sync[:direct_messages]
    return if @sync[:direct_messages].empty?

    Rails.logger.debug ' - searching for direct_messages'

    counter = 0
    @tweet.client.direct_messages.each { |tweet|

      break if @sync[:direct_messages][:limit] && @sync[:direct_messages][:limit] <= counter
      break if Ticket::Article.find_by(message_id: tweet.id)

      @tweet.to_group(tweet, @sync[:direct_messages][:group_id])

      counter += 1
    }
  end
end
