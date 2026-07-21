# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# audit logging for checklist templates, showing item texts instead of ids in the snapshots
module ChecklistTemplate::HasAuditLogs
  extend ActiveSupport::Concern

  include ::HasAuditLogs

  included do
    # remember the item texts before the dependent items are destroyed along with the record
    before_destroy :audit_log_remember_item_texts, prepend: true
  end

  private

  def audit_log_remember_item_texts
    @audit_log_item_texts = audit_log_item_texts
  end

  def audit_log_item_texts
    items.to_h do |item|
      [item.id.to_s, item.text]
    end
  end

  # show item texts under a sorted_item_names key instead of the sorted_item_ids in the audit log
  def audit_log_mask(snapshot)
    return snapshot if !snapshot.key?('sorted_item_ids')

    texts = (@audit_log_item_texts || {}).merge(audit_log_item_texts)

    snapshot
      .except('sorted_item_ids')
      .merge('sorted_item_names' => snapshot['sorted_item_ids'].map { |item_id| texts.fetch(item_id.to_s, item_id) })
  end
end
