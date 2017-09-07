class Sessions::Backend::Base

  def initialize(user, asset_lookup, client, client_id, ttl = 10)
    @user         = user
    @client       = client
    @client_id    = client_id
    @ttl          = ttl
    @asset_lookup = asset_lookup
    @last_change  = nil
  end

  def asset_needed?(record)
    class_name = record.class.to_s
    if !@asset_lookup || !@asset_lookup[class_name] || !@asset_lookup[class_name][record.id]
      @asset_lookup[class_name] ||= {}
      @asset_lookup[class_name][record.id] = {
        updated_at: record.updated_at,
        pushed_at: Time.zone.now,
      }
      return true
    end

    if (!@asset_lookup[class_name][record.id][:updated_at] || @asset_lookup[class_name][record.id][:updated_at] < record.updated_at) ||
       (!@asset_lookup[class_name][record.id][:pushed_at] || @asset_lookup[class_name][record.id][:pushed_at] > Time.zone.now - 45.seconds)
      @asset_lookup[class_name][record.id] = {
        updated_at: record.updated_at,
        pushed_at: Time.zone.now,
      }
      return true
    end
    false
  end

end
