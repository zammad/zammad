# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Ticket::Article::Sender < ApplicationModel
  include ChecksLatestChangeObserved
  validates :name, presence: true
end
