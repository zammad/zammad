class Sessions::Backend::Base

  attr_writer :user

  def initialize(user, asset_lookup, client, client_id, ttl = 10)
    @user         = user
    @client       = client
    @client_id    = client_id
    @ttl          = ttl
    @asset_lookup = asset_lookup
    @last_change  = nil
  end

  def asset_push(record, assets)
    class_name = record.class.to_s
    @asset_lookup[class_name] ||= {}
    @asset_lookup[class_name][record.id] = {
      updated_at: record.updated_at,
      pushed_at: Time.zone.now,
    }
    record.assets(assets)
  end

  def asset_needed?(record)
    return false if !asset_needed_by_updated_at?(record.class.to_s, record.id, record.updated_at)
    true
  end

  def asset_needed_by_updated_at?(class_name, record_id, updated_at)
    return true if @asset_lookup.blank?
    return true if @asset_lookup[class_name].blank?
    return true if @asset_lookup[class_name][record_id].blank?
    return true if @asset_lookup[class_name][record_id][:updated_at] < updated_at
    return true if @asset_lookup[class_name][record_id][:pushed_at].blank?
    return true if @asset_lookup[class_name][record_id][:pushed_at] < Time.zone.now - 2.hours
    false
  end

end
