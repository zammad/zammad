# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Organization < ApplicationModel
  load 'organization/permission.rb'
  include Organization::Permission
  load 'organization/assets.rb'
  include Organization::Assets
  extend Organization::Search
  load 'organization/search_index.rb'
  include Organization::SearchIndex

  has_and_belongs_to_many :users
  has_many                :members,  class_name: 'User'
  validates               :name,     presence: true

  before_create :domain_cleanup
  before_update :domain_cleanup

  activity_stream_support permission: 'admin.role'
  history_support
  search_index_support
  notify_clients_support
  latest_change_support

  private

  def domain_cleanup
    return if !domain
    return if domain.empty?
    domain.gsub!(/@/, '')
    domain.gsub!(/\s*/, '')
    domain.strip!
    domain.downcase!
  end

  def cache_delete
    super

    # delete asset caches
    key = "Organization::member_ids::#{id}"
    Cache.delete(key)
  end
end
