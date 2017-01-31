# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module ApplicationModel::HasLatestChangeTimestamp
  extend ActiveSupport::Concern

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

  get latest updated_at object timestamp

  latest_change = Ticket.latest_change

returns

  result = timestamp

=end

    def latest_change
      key        = "#{new.class.name}_latest_change"
      updated_at = Cache.get(key)

      # if we do not have it cached, do lookup
      if !updated_at
        o = select(:updated_at).order(updated_at: :desc).limit(1).first
        if o
          updated_at = o.updated_at
          latest_change_set(updated_at)
        end
      end
      updated_at
    end

    def latest_change_set(updated_at)
      key        = "#{new.class.name}_latest_change"
      expires_in = 31_536_000 # 1 year

      if updated_at.nil?
        Cache.delete(key)
      else
        Cache.write(key, updated_at, { expires_in: expires_in })
      end
    end
  end
end
