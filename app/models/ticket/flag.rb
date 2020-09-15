# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Ticket::Flag < ApplicationModel
  belongs_to :ticket

  association_attributes_ignored :ticket
end
