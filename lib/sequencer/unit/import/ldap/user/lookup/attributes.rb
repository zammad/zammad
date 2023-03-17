# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::User::Lookup::Attributes < Sequencer::Unit::Import::Common::Model::FindBy::UserAttributes

  uses :found_ids, :external_sync_source

  private

  def lookup(attribute:, value:)
    entries = model_class.where(attribute => value).to_a
    return if entries.blank?

    not_synced(entries)
  end

  def not_synced(entries)
    entries.find { |entry| not_synced?(entry) }
  end

  def not_synced?(entry)
    found_ids.exclude?(entry.id)
  end
end
