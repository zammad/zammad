# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Ticket::StateType < ApplicationModel
  include CanBeImported
  include ChecksHtmlSanitized
  include ChecksLatestChangeObserved

  has_many :states, class_name: 'Ticket::State', inverse_of: :state_type

  validates :name, presence: true

  sanitized_html :note
end
