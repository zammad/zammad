# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Karma::Activity < ApplicationModel
  self.table_name = 'karma_activities'
  validates :name, presence: true
end
