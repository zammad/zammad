# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Backend::ActivityStream < Sessions::Backend::Base

  attr_writer :user

  def initialize(user, asset_lookup, client = nil, client_id = nil, ttl = 25) # rubocop:disable Lint/MissingSuper
    @user         = user
    @client       = client
    @client_id    = client_id
    @ttl          = ttl
    @asset_lookup = asset_lookup
    @last_ids     = nil
  end

  def load

    # get whole collection
    activity_stream = @user.activity_stream(25)

    # The whole list is compared, not only its newest entry: a changed dashboard setting can
    #   remove entries from it or empty it, and open dashboards have to follow.
    ids = activity_stream.map(&:id)
    return if ids == @last_ids

    @last_ids = ids

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
