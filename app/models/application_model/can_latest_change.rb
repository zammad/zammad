# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationModel::CanLatestChange
  extend ActiveSupport::Concern

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

  get latest updated_at object timestamp

  latest_change = object.latest_change

returns

  result = timestamp

=end

    def latest_change
      key        = "#{name}_latest_change"
      updated_at = Cache.read(key)

      return updated_at if updated_at

      # if we do not have it cached, do lookup
      updated_at = order(updated_at: :desc).limit(1).pluck(:updated_at).first

      return if !updated_at

      latest_change_set(updated_at)
      updated_at
    end

    def latest_change_set(updated_at)
      key        = "#{name}_latest_change"
      expires_in = 86_400 # 1 day

      if updated_at.nil?
        Cache.delete(key)
      else
        Cache.write(key, updated_at, { expires_in: expires_in })
      end
    end
  end
end
