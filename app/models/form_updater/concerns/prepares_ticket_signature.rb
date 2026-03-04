# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::PreparesTicketSignature
  extend ActiveSupport::Concern

  def resolve
    maybe_prepare_ticket_signature if agent?

    super
  end

  private

  def maybe_prepare_ticket_signature
    # Prepare signature on initial load, when group/article type has changed, or when
    # restoring autosave (applyTaskbarState). The last case is necessary because the
    # autosave body is written to the editor BEFORE the signature watcher fires on the
    # frontend; without a fresh signature in the response the watcher never fires and
    # the editor keeps whatever signature (if any) was embedded in the saved HTML.
    return if !meta[:initial] &&
              !meta.dig(:additional_data, 'applyTaskbarState') &&
              meta.dig(:changed_field, :name) != 'group_id' &&
              meta.dig(:changed_field, :name) != 'articleSenderType'

    result_initialize_field('body')

    if group_signature.nil?
      result['body'][:signature] = nil
      return
    end

    # Fake a ticket object for create screen if a group is present (#4448).
    object = Struct.new(:group).new(group) if object.nil?

    result['body'][:signature] = {
      internalId:   group_signature.id,
      renderedBody: NotificationFactory::Renderer.new(
        objects:  { user: current_user, ticket: object },
        template: group_signature.body,
        escape:   false
      ).render(debug_errors: false),
    }
  end

  def group_signature
    return nil if group.nil? || group.signature_id.nil?

    @group_signature ||= Signature.find(group.signature_id)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def group
    # Check first in the result, then in the data.
    #   It could happen the group value is coming from a dirty field in the taskbar.
    @group ||= Group.find(result.dig('group_id', :value) || data['group_id'])
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def agent?
    current_user.permissions?('ticket.agent')
  end
end
