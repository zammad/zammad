# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
      data = order('updated_at DESC, id DESC').limit(1).pick(:id, :updated_at)
      return if data.blank?

      "#{data[0]},#{data[1]&.to_s(:nsec)}"
    end
  end
end
