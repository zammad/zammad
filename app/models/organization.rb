# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Organization < ApplicationModel
  include LogsActivityStream
  include NotifiesClients
  include LatestChangeObserved
  include Historisable
  include SearchIndexed

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

  activity_stream_permission 'admin.role'

  private

  def domain_cleanup
    return if domain.blank?
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
