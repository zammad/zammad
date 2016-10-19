# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class PostmasterFilter < ApplicationModel
  store     :perform
  store     :match
  validates :name, presence: true
end
