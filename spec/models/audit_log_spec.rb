# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AuditLog, type: :model do
  describe '#search_index_attribute_lookup' do
    it 'does not expand the auditable object' do
      expect(create(:audit_log).search_index_attribute_lookup).not_to have_key('auditable')
    end
  end

  describe '#set_source_ip' do
    context 'when a request ip is present' do
      before { UserInfo.current_ip = '198.51.100.7' }

      after { UserInfo.current_ip = nil }

      it 'stores the request ip' do
        expect(create(:audit_log, source_ip: nil).source_ip).to eq('198.51.100.7')
      end
    end

    context 'when running in the rails console' do
      before do
        allow(Rails).to receive(:const_defined?).and_call_original
        allow(Rails).to receive(:const_defined?).with(:Console).and_return(true)
      end

      it 'marks the entry with a rails console indicator' do
        expect(create(:audit_log, source_ip: nil).source_ip).to eq('Rails console')
      end
    end

    context 'without any source information' do
      it 'keeps the source ip empty' do
        expect(create(:audit_log, source_ip: nil).source_ip).to be_nil
      end
    end
  end

  describe '.suspend' do
    let(:role) { create(:role) }

    before do
      Setting.set('system_init_done', true)
    end

    it 'suppresses audit logging inside the block' do
      expect { described_class.suspend { role.update!(name: 'Suspended') } }
        .not_to change { described_class.where(auditable: role).count }
    end

    it 'suppresses role assignment logging inside the block' do
      user = create(:admin)
      user.reload

      expect { described_class.suspend { user.roles << create(:role, :agent) } }
        .not_to change { described_class.where(auditable: user).count }
    end

    it 'restores audit logging after the block' do
      described_class.suspend { role.update!(name: 'Suspended') }

      expect { role.update!(name: 'Audited') }
        .to change { described_class.where(auditable: role).count }.by(1)
    end

    it 'is available as a Transaction.execute option' do
      expect { Transaction.execute(disable_audit_log: true) { role.update!(name: 'Suspended') } }
        .not_to change { described_class.where(auditable: role).count }
    end
  end

  describe 'association updates in nested transactions' do
    let(:role)             { create(:role) }
    let(:permission)       { create(:permission) }
    let(:other_permission) { create(:permission) }

    before do
      Setting.set('system_init_done', true)
      role
      permission
      other_permission
    end

    it 'discards changes from a rolled back nested transaction' do
      ActiveRecord::Base.transaction do
        role.permissions << permission

        ActiveRecord::Base.transaction(requires_new: true) do
          role.permissions << other_permission
          raise ActiveRecord::Rollback
        end
      end

      entry = described_class.find_by(auditable: role, action_type: 'update')
      expect(entry.value_to).to eq('permissions' => [permission.name])
    end

    it 'writes no entry when all changes were rolled back' do
      expect do
        ActiveRecord::Base.transaction do
          ActiveRecord::Base.transaction(requires_new: true) do
            role.permissions << permission
            raise ActiveRecord::Rollback
          end
        end
      end.not_to change { described_class.where(auditable: role, action_type: 'update').count }
    end

    it 'merges changes from a committed nested transaction into a single entry', :aggregate_failures do
      expect do
        ActiveRecord::Base.transaction do
          role.permissions << permission

          ActiveRecord::Base.transaction(requires_new: true) do
            role.permissions << other_permission
          end
        end
      end.to change { described_class.where(auditable: role, action_type: 'update').count }.by(1)

      entry = described_class.find_by(auditable: role, action_type: 'update')
      expect(entry.value_to['permissions']).to contain_exactly(permission.name, other_permission.name)
    end

    it 'keeps the latest attribute value when updates span nested transactions', :aggregate_failures do
      original_name = role.name

      ActiveRecord::Base.transaction do
        role.update!(name: 'Role B')

        ActiveRecord::Base.transaction(requires_new: true) do
          role.update!(name: 'Role C')
        end

        role.update!(name: 'Role D')
      end

      entry = described_class.find_by(auditable: role, action_type: 'update')
      expect(entry.value_from['name']).to eq(original_name)
      expect(entry.value_to['name']).to eq('Role D')
    end
  end

  describe 'suspension during migrations' do
    let(:role) { create(:role) }

    let(:migration_class) do
      target = role

      Class.new(ActiveRecord::Migration[8.0]) do
        define_method(:up) { target.update!(name: 'Migrated') }
      end
    end

    before do
      Setting.set('system_init_done', true)

      ActiveRecord::Migration.verbose = false
    end

    after do
      ActiveRecord::Migration.verbose = true
    end

    it 'suppresses audit logging while a migration runs' do
      expect { migration_class.new.migrate(:up) }
        .not_to change { described_class.where(auditable: role).count }
    end

    it 'restores audit logging after the migration' do
      migration_class.new.migrate(:up)

      expect { role.update!(name: 'Audited') }
        .to change { described_class.where(auditable: role).count }.by(1)
    end
  end

  describe '.cleanup' do
    let(:audit_log) { create(:audit_log) }

    it 'does not delete new entries' do
      audit_log
      described_class.cleanup
      expect { audit_log.reload }.not_to raise_error
    end

    it 'does delete old entries' do
      travel_to 13.months.ago
      audit_log
      travel_back
      described_class.cleanup
      expect { audit_log.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'does make sure that the cleanup returns truthy value for scheduler' do
      expect(described_class.cleanup).to be(true)
    end
  end
end
