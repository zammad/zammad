# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Organization < ApplicationModel
  include Organization::Assets
  extend Organization::Search

  has_and_belongs_to_many  :users
  validates                :name, :presence => true
  activity_stream_support  :role => 'Admin'

end