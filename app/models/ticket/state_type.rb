# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Ticket::StateType < ApplicationModel
  include HasDefaultModelUserRelations

  include CanBeImported
  include ChecksHtmlSanitized

  has_many :states, class_name: 'Ticket::State', inverse_of: :state_type

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  validates :note, length: { maximum: 250 }
  sanitized_html :note

  CATEGORIES = {
    open:                   ['new', 'open', 'pending reminder', 'pending action'],
    pending_reminder:       ['pending reminder'],
    pending_action:         ['pending action'],
    pending:                ['pending reminder', 'pending action'],
    work_on:                %w[new open],
    work_on_all:            ['new', 'open', 'pending reminder'],
    # Legacy systems may have a state type 'removed', which should still be available.
    viewable:               ['new', 'open', 'pending reminder', 'pending action', 'closed', 'removed'],
    viewable_agent_new:     ['new', 'open', 'pending reminder', 'pending action', 'closed'],
    viewable_agent_edit:    ['open', 'pending reminder', 'pending action', 'closed'],
    viewable_customer_new:  %w[new closed],
    viewable_customer_edit: %w[open closed],
    closed:                 %w[closed],
    merged:                 %w[merged],
  }.with_indifferent_access.freeze

  def self.names_in_category(category)
    CATEGORIES.fetch category
  rescue KeyError
    raise ArgumentError, "No such ticket state category (#{category})"
  end
end
