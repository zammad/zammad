class Sessions::Backend::Base
  def initialize(user, asset_lookup, client, client_id, ttl = 30)
    @user         = user
    @client       = client
    @client_id    = client_id
    @ttl          = ttl
    @asset_lookup = asset_lookup
    @last_change  = nil
  end

  def asset_needed?(record)
    class_name = record.class.to_s
    if !@asset_lookup || !@asset_lookup[class_name] || !@asset_lookup[class_name][record.id] || @asset_lookup[class_name][record.id] < record.updated_at
      if !@asset_lookup[class_name]
        @asset_lookup[class_name] = {}
      end
      @asset_lookup[class_name][record.id] = record.updated_at
      return true
    end
    false
  end

end
