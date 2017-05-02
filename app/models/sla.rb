# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Sla < ApplicationModel
  include ChecksClientNotification
  include ChecksConditionValidation

  load 'sla/assets.rb'
  include Sla::Assets

  store      :condition
  store      :data
  validates  :name, presence: true
  belongs_to :calendar
end
