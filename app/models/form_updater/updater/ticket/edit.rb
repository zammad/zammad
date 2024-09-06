# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::Ticket::Edit < FormUpdater::Updater
  # include FormUpdater::Concerns::AppliesTaskbarState
  include FormUpdater::Concerns::ChecksCoreWorkflow
  include FormUpdater::Concerns::HasSecurityOptions
  # include FormUpdater::Concerns::StoresTaskbarState

  core_workflow_screen 'edit'

  # apply_state_group_keys %w[ticket article]
  # store_state_group_key 'ticket'
  # store_state_group_skip_keys ['article']

  def resolve
    set_default_follow_up_state if !meta[:initial]

    super
  end

  def object_type
    ::Ticket
  end

  def handle_updater_flags
    flags[:newArticlePresent] = result['articleType'].present?
  end

  def after_store_taskbar_preperation(state)
    return if data.dig('article', 'articleType').nil?

    # TODO: change to "type", but for now we need to keep it as "articleType" for compatibility reasons without apply_value mapping.
    state['article']['type'] = state['article'].delete('articleType')
  end

  private

  def article_body_empty?
    !data.dig('article', 'body') || data['article']['body'].empty?
  end

  def state_changed?
    data['state_id'] != object.state.id
  end

  def customer?
    return false if current_user.permissions?('ticket.agent') && current_user.groups.access(:read).include?(object.group)
    return true if current_user.permissions?('ticket.customer')

    false
  end

  def set_resultant_field_values

    # Prevent multiple changes to the default follow-up state.
    result['isDefaultFollowUpStateSet'][:value] = true

    result['state_id'][:value] = ::Ticket::State.find_by(default_follow_up: true)&.id
  end

  # Ported from App.TicketZoom.setDefaultFollowUpState().
  def set_default_follow_up_state
    result_initialize_field('state_id')
    result_initialize_field('isDefaultFollowUpStateSet')

    # Set default state if body is present.
    return if article_body_empty?

    # And the state was not changed.
    return if state_changed?

    # And we are in the customer context.
    return if !customer?

    # And the default state was not set before.
    return if data['isDefaultFollowUpStateSet']

    # And only if the ticket is not in the default create state (e.g. "new").
    return if object.state.default_create

    set_resultant_field_values
  end
end
