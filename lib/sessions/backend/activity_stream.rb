# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Backend::ActivityStream < Sessions::Backend::Base

  attr_writer :user

  def initialize(user, asset_lookup, client = nil, client_id = nil, ttl = 25) # rubocop:disable Lint/MissingSuper
    @user         = user
    @client       = client
    @client_id    = client_id
    @ttl          = ttl
    @asset_lookup = asset_lookup
    @last_change  = nil
  end

  def load

    # get whole collection
    activity_stream = @user.activity_stream(25)
    if activity_stream && !activity_stream.first
      return
    end

    if activity_stream&.first && activity_stream.first['created_at'] == @last_change
      return
    end

    # update last changed
    if activity_stream&.first
      @last_change = activity_stream.first['created_at']
    end

    assets = {}
    item_ids = []
    activity_stream.each do |item|
      begin
        assets = item.assets(assets)
      rescue ActiveRecord::RecordNotFound
        next
      end

      item_ids.push item.id
    end

    {
      record_ids: item_ids,
      assets:     assets,
    }
  end

  def push
    return if !to_run?

    @time_now = Time.zone.now.to_i

    data = load

    return if data.blank?

    if !@client
      return {
        event:      'activity_stream_rebuild',
        collection: 'activity_stream',
        data:       data,
      }
    end

    @client.log "push activity_stream #{data.first.class} for user #{@user.id}"
    @client.send(
      event:      'activity_stream_rebuild',
      collection: 'activity_stream',
      data:       data,
    )
  end

end
