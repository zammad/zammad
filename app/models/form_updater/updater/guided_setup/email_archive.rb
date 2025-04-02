# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::GuidedSetup::EmailArchive < FormUpdater::Updater
  def authorized?
    current_user.permissions?('admin.wizard')
  end

  def resolve
    if meta[:initial]
      prepare_initial_data
    end

    super
  end

  private

  def prepare_initial_data
    result['archive_state_id'] = initial_archive_state_id
  end

  def initial_archive_state_id
    {
      initialValue: default_archive_state_id,
      options:      archive_state_options,
    }
  end

  def default_archive_state_id
    ::Ticket::State.active.by_category(:closed).pick(:id)
  end

  def archive_state_options
    FormUpdater::Relation::TicketState.new(
      context:,
      current_user:,
      filter_ids:   ::Ticket::State.by_category(:archivable_into).active.pluck(:id),
    ).options
  end
end
