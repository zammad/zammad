# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'ChecklistTemplate::HasAuditLogs' do
  subject(:record) { create(described_class.name.underscore, items: %w[Alpha Beta]) }

  let(:audit_logs) { AuditLog.where(auditable_type: described_class.name, auditable_id: record.id) }

  before do
    Setting.set('system_init_done', true)
  end

  it 'logs item texts instead of ids when items are replaced' do
    record.replace_items! %w[Alpha Gamma]

    expect(audit_logs.where(action_type: 'update').reorder(id: :desc).first).to have_attributes(
      value_from:  include('sorted_item_names' => %w[Alpha Beta]),
      value_to:    include('sorted_item_names' => %w[Alpha Gamma]),
      preferences: include('changed_attributes' => include('sorted_item_names')),
    )
  end

  it 'logs item texts instead of ids when the record is destroyed' do
    record.destroy!

    expect(audit_logs.find_by(action_type: 'destroy')).to have_attributes(
      value_from: include('sorted_item_names' => %w[Alpha Beta]),
    )
  end

  it 'does not log the sorted item ids' do
    record.replace_items! %w[Alpha Gamma]

    expect(audit_logs.where(action_type: 'update').reorder(id: :desc).first).to have_attributes(
      value_from: not_include('sorted_item_ids'),
      value_to:   not_include('sorted_item_ids'),
    )
  end
end
