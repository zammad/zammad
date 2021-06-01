# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Backend::Base

  attr_writer :user, :time_now

  def initialize(user, asset_lookup, client, client_id, ttl = 10)
    @user         = user
    @client       = client
    @client_id    = client_id
    @ttl          = ttl
    @asset_lookup = asset_lookup
    @last_change  = nil
  end

  def to_run?
    return true if !@time_now
    return true if Time.zone.now.to_i > (@time_now + @ttl)

    false
  end

  def asset_push(record, assets)
    if !@time_now
      @time_now = Time.zone.now.to_i
    end
    class_name = record.class.to_s
    @asset_lookup[class_name] ||= {}
    @asset_lookup[class_name][record.id] = {
      updated_at: record.updated_at,
      pushed_at:  @time_now,
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
    return true if @asset_lookup[class_name][record_id][:pushed_at] < @time_now - 7200

    false
  end

end
