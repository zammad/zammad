# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module AuditLog::LogsAssociationUpdates
  extend ActiveSupport::Concern

  ATTRIBUTES_KEY = :attributes

  module ClassMethods # rubocop:disable Metrics/ModuleLength
=begin

log the update of an association of a record in the audit log

  AuditLog.log_association_update(record: role, action_type: 'update', key: 'permissions', added: permission.name)

an array key nests the values one level deeper, e.g. per group under a group_permissions key

  AuditLog.log_association_update(record: role, action_type: 'update', key: ['group_permissions', group.name], removed: 'read')

changes are collected per record and action type and written as a single entry when the
surrounding database transaction commits, so that e.g. changing multiple permissions of
a role in the admin interface results in one entry holding all added and removed values,
changes inside a nested (requires_new) transaction are discarded when it rolls back

changes while the record is being created are not logged - they are part of creating
the record, not a later change to an existing record - unless allow_create is set

=end

    def log_association_update(record:, action_type:, key:, added: nil, removed: nil, allow_create: false)
      return if suspended?
      return if !Setting.get('system_init_done')
      return if !record.persisted?
      return if record.audit_log_creating? && !allow_create

      # skip if the audit_logs table does not exist yet, e.g. during migrations
      # that modify audited records before the table is created
      return if !ActiveRecord::Base.connection.data_source_exists?('audit_logs')

      changes = association_update_buffer(record, action_type)[key] ||= { 'added' => [], 'removed' => [] }
      changes['added'].concat(Array.wrap(added))
      changes['removed'].concat(Array.wrap(removed))

      # association callbacks normally run inside a transaction, flush directly if not
      association_update_flush(record, action_type) if ActiveRecord::Base.current_transaction.closed?
    end

=begin

log an attribute update of a record in the audit log, merged with association updates

  AuditLog.log_attribute_update(record: role, value_from: {...}, value_to: {...}, changed_attributes: ['name'])

the changes are collected in the same buffer as association updates with action type
'update', so that e.g. renaming a role and changing its permissions in one transaction
results in a single update entry

=end

    def log_attribute_update(record:, value_from:, value_to:, changed_attributes:)
      return if suspended?
      return if !Setting.get('system_init_done')
      return if !record.send(:audit_log_condition_met?)
      return if !ActiveRecord::Base.connection.data_source_exists?('audit_logs')

      entry = association_update_buffer(record, 'update')[ATTRIBUTES_KEY] ||= { 'value_from' => {}, 'value_to' => {}, 'changed_attributes' => [], 'sequence' => {} }
      entry['value_from'] = value_from.merge(entry['value_from'])
      entry['value_to']   = entry['value_to'].merge(value_to)
      entry['changed_attributes'] |= changed_attributes

      # remember the write order per attribute so merging nested buffers keeps the latest value
      sequence = Thread.current[:audit_log_attribute_sequence] = Thread.current[:audit_log_attribute_sequence].to_i + 1
      value_to.each_key { |attribute| entry['sequence'][attribute] = sequence }

      association_update_flush(record, 'update') if ActiveRecord::Base.current_transaction.closed?
    end

    private

    def association_update_buffer(record, action_type)
      store       = Thread.current[:audit_log_association_updates] ||= {}
      transaction = ActiveRecord::Base.current_transaction

      # scope by transaction so changes inside a rolled back nested (requires_new) transaction are discarded
      key = [transaction, record.class.name, record.id, action_type]

      store[key] ||= begin
        if transaction.open?
          transaction.after_commit { association_update_flush(record, action_type) }
          transaction.after_rollback { store.delete(key) }
        end

        {}
      end
    end

    def association_update_flush(record, action_type)
      changes = association_update_merge(record, action_type)
      return if changes.blank?

      # skip if the record is gone, e.g. the removal of all group permissions on role deletion
      return if !record.class.exists?(record.id)

      attributes_change = changes.delete(ATTRIBUTES_KEY)

      value_from, value_to = association_update_values(changes)
      preferences = {}

      if attributes_change
        preferences[:changed_attributes] = attributes_change['changed_attributes'] | value_from.keys | value_to.keys
        value_from = attributes_change['value_from'].merge(value_from)
        value_to   = attributes_change['value_to'].merge(value_to)
      end

      return if value_from.blank? && value_to.blank?

      # set auditable_id/type directly instead of the object to avoid touching (autosaving) the record
      create!(
        action_type:    action_type,
        auditable_id:   record.id,
        auditable_type: record.class.name,
        auditable_name: record.send(:audit_log_name),
        user_id:        UserInfo.current_user_id,
        value_from:     value_from,
        value_to:       value_to,
        preferences:    preferences,
      )
    end

    # merge the buffers of all (nested) transactions of the record so a single entry is written on commit
    def association_update_merge(record, action_type)
      store = Thread.current[:audit_log_association_updates]
      return if store.blank?

      keys = store.keys.select { |key| key[1..] == [record.class.name, record.id, action_type] }

      keys.map { |key| store.delete(key) }.reduce(nil) do |merged, buffer|
        next buffer if !merged

        buffer.each_with_object(merged) do |(key, change), result|
          result[key] = if key == ATTRIBUTES_KEY
                          association_update_merge_attributes(result[key], change)
                        else
                          association_update_merge_changes(result[key], change)
                        end
        end
      end
    end

    def association_update_merge_attributes(entry, change)
      return change if !entry

      # buffers are ordered by creation, not by last write, so the sequence decides which value_to is newer
      value_to = entry['value_to'].merge(change['value_to']) do |attribute, entry_value, change_value|
        entry['sequence'][attribute] > change['sequence'][attribute] ? entry_value : change_value
      end

      {
        'value_from'         => change['value_from'].merge(entry['value_from']),
        'value_to'           => value_to,
        'changed_attributes' => entry['changed_attributes'] | change['changed_attributes'],
        'sequence'           => entry['sequence'].merge(change['sequence']) { |_attribute, entry_sequence, change_sequence| [entry_sequence, change_sequence].max },
      }
    end

    def association_update_merge_changes(entry, change)
      return change if !entry

      {
        'added'   => entry['added'] + change['added'],
        'removed' => entry['removed'] + change['removed'],
      }
    end

    def association_update_values(changes)
      value_from = {}
      value_to   = {}

      changes.each do |key, change|
        added   = change['added'] - change['removed']
        removed = change['removed'] - change['added']

        association_update_values_store(value_from, key, removed) if removed.present?
        association_update_values_store(value_to, key, added) if added.present?
      end

      [value_from, value_to]
    end

    def association_update_values_store(values, key, entries)
      main_key, sub_key = key

      if sub_key
        (values[main_key] ||= {})[sub_key] = entries
      else
        values[main_key] = entries
      end
    end
  end
end
