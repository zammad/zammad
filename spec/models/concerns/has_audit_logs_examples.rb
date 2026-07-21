# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'HasAuditLogs' do |update_attribute:, update_value:, name_attribute: 'name'|
  subject { create(described_class.name.underscore) }

  describe 'auto-creation of audit log records' do
    let(:audit_logs) { AuditLog.where(auditable_type: described_class.name) }

    before do
      Setting.set('system_init_done', true)
    end

    context 'when record is created' do
      it 'creates an audit log record' do
        expect { subject }.to change(audit_logs.where(action_type: 'create'), :count).by(1)
      end

      it 'logs an empty value_from and a full snapshot as value_to' do
        subject

        expect(audit_logs.find_by(action_type: 'create', auditable_id: subject.id)).to have_attributes(
          value_from: {},
          value_to:   include(update_attribute => subject[update_attribute]),
        )
      end
    end

    context 'when record is updated' do
      let!(:old_value) { subject[update_attribute] }

      it 'creates an audit log record' do
        expect { subject.update!(update_attribute => update_value) }
          .to change(audit_logs.where(action_type: 'update', auditable_id: subject.id), :count).by(1)
      end

      it 'logs old and new snapshots' do
        subject.update!(update_attribute => update_value)

        expect(audit_logs.where(action_type: 'update', auditable_id: subject.id).sorted.first).to have_attributes(
          value_from: include(update_attribute => old_value),
          value_to:   include(update_attribute => update_value),
        )
      end

      it 'creates no audit log record if only ignored attributes changed' do
        subject

        expect { subject.update!(updated_at: 1.minute.from_now) }
          .not_to change(audit_logs.where(auditable_id: subject.id), :count)
      end
    end

    context 'when record is destroyed' do
      it 'creates an audit log record' do
        subject

        expect { subject.destroy! }.to change(audit_logs.where(action_type: 'destroy'), :count).by(1)
      end

      it 'logs a full snapshot as value_from' do
        subject.destroy!

        expect(audit_logs.find_by(action_type: 'destroy', auditable_id: subject.id)).to have_attributes(
          value_from: include(update_attribute => subject[update_attribute]),
          value_to:   {},
        )
      end
    end

    describe 'auditable name' do
      it 'records the name snapshot of the object' do
        subject

        expect(audit_logs.find_by(action_type: 'create', auditable_id: subject.id).auditable_name)
          .to eq(subject[name_attribute])
      end
    end

    describe 'acting user' do
      it 'records the current user with fullname snapshot' do
        UserInfo.with_user_id(1) { subject }

        expect(audit_logs.find_by(action_type: 'create', auditable_id: subject.id)).to have_attributes(
          user_id:       1,
          user_fullname: User.find(1).fullname,
        )
      end
    end

    describe 'source ip' do
      before { UserInfo.current_ip = '192.0.2.42' }

      after { UserInfo.current_ip = nil }

      it 'records the current source ip' do
        subject

        expect(audit_logs.find_by(action_type: 'create', auditable_id: subject.id).source_ip).to eq('192.0.2.42')
      end
    end
  end
end
