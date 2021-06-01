# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasTicketCreateScreenImpact
  extend ActiveSupport::Concern

  included do
    after_commit :push_ticket_create_screen
  end

  def push_ticket_create_screen?
    return true if destroyed?

    %w[id name active].any? do |attribute|
      saved_change_to_attribute?(attribute)
    end
  end

  def push_ticket_create_screen
    return if Setting.get('import_mode')
    return if !push_ticket_create_screen?

    push_ticket_create_screen_background_job
  end

  def push_ticket_create_screen_background_job
    TicketCreateScreenJob.set(wait: 10.seconds).perform_later
  end
end
