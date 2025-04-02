# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Conversation::User < Sequencer::Unit::Import::Freshdesk::SubSequence::Generic
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_action :skipped, :failed

  uses :dry_run, :import_job, :resource, :field_map, :id_map, :skip_initial_contacts

  def process
    return if !skip_initial_contacts || user_exists? || resource['user_id'].blank?

    ::Sequencer.process('Import::Freshdesk::Contact',
                        parameters: {
                          import_job: import_job,
                          dry_run:    dry_run,
                          field_map:  field_map,
                          id_map:     id_map,
                          contact_id: resource['user_id'],
                          resource:   {},
                        })
  end

  private

  def user_exists?
    id_map['User'][resource['user_id']].present?
  end
end
