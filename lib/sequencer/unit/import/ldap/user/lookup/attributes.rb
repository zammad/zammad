# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::User::Lookup::Attributes < Sequencer::Unit::Import::Common::Model::FindBy::UserAttributes

  uses :found_ids, :external_sync_source

  private

  def lookup(attribute:, value:)
    entries = scope_for(attribute, value).to_a
    return if entries.blank?

    not_synced(entries)
  end

  def scope_for(attribute, value)
    return model_class.by_login(value) if attribute == :login

    model_class.where(attribute => value)
  end

  def not_synced(entries)
    entries.find { |entry| not_synced?(entry) }
  end

  def not_synced?(entry)
    found_ids.exclude?(entry.id)
  end
end
