# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Organization < ApplicationModel
  require 'organization/assets'
  include Organization::Assets
  extend Organization::Search
  include Organization::SearchIndex

  has_and_belongs_to_many  :users
  has_many                 :members,  :class_name => 'User'
  validates                :name,     :presence => true

  activity_stream_support  :role => 'Admin'
  history_support
  search_index_support

end