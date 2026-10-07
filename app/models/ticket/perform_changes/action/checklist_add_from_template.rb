# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Ticket::PerformChanges::Action::ChecklistAddFromTemplate < Ticket::PerformChanges::Action

  def self.phase
    :after_save
  end

  def execute(...)
    return skip('ticket was deleted') if record.destroyed?
    return skip('checklist feature is disabled') if !Setting.get('checklist')

    template = ChecklistTemplate.find_by(id: template_id)
    return skip("checklist template #{template_id} not found") if !template

    Checklist.add_from_template!(record, template)
  rescue Exceptions::UnprocessableContent, ActiveRecord::RecordInvalid => e
    # An inactive template and the item limit are rejected before anything is written; a ticket that
    #   fails its own validation while the checklist takes it has been rolled back to the savepoint.
    skip(e.message)
  end

  private

  def template_id
    execution_data['checklist_template_id']
  end

  def skip(reason)
    Rails.logger.info "Skip checklist template for Ticket/#{id} from #{origin} (#{performable.try(:name)}/#{performable.try(:id)}): #{reason}"
  end
end
