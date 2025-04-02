# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
      maximum(:updated_at)&.to_fs(:nsec)
    end
  end
end
