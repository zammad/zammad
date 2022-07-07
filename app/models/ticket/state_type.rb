# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Ticket::StateType < ApplicationModel
  include CanBeImported
  include ChecksHtmlSanitized

  has_many :states, class_name: 'Ticket::State', inverse_of: :state_type

  validates :name, presence: true

  validates :note, length: { maximum: 250 }
  sanitized_html :note
end
