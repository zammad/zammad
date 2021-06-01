# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class StatsStore < ApplicationModel
  include HasSearchIndexBackend

  belongs_to :stats_storable, polymorphic: true

  store :data

=begin

  item = StatsStore.sync(
    stats_storable: current_user,
    key:            'dashboard',
    data:           {some data},
  )

=end

  def self.sync(params)

    data = params[:data]
    params.delete(:data)

    item = find_by(params)

    if item
      item.data = data
      item.save
      return item
    end

    params[:data] = data
    params[:created_by_id] = 1
    create(params)
  end

=begin

cleanup old stats store

  StatsStore.cleanup

optional you can put the max oldest stats store entries as argument

  StatsStore.cleanup(12.months)

=end

  def self.cleanup(diff = 12.months)
    StatsStore.where('updated_at < ?', Time.zone.now - diff).delete_all
    true
  end

end
