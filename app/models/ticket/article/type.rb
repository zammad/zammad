# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Ticket::Article::Type < ApplicationModel
  include ChecksLatestChangeObserved
  validates :name, presence: true
end
