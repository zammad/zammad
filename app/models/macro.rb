# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Macro < ApplicationModel
  store     :perform
  validates :name, presence: true

end
