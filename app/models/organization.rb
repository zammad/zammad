# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Organization < ApplicationModel
  include Organization::Permission
  load 'organization/assets.rb'
  include Organization::Assets
  extend Organization::Search
  include Organization::SearchIndex

  has_and_belongs_to_many :users
  has_many                :members,  class_name: 'User'
  validates               :name,     presence: true

  activity_stream_support role: Z_ROLENAME_ADMIN
  history_support
  search_index_support
  notify_clients_support
  latest_change_support

  private

  def cache_delete
    super

    # delete asset caches
    key = "Organization::member_ids::#{id}"
    Cache.delete(key)
  end
end
