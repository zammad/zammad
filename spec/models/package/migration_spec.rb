# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Package::Migration, type: :model do
  describe '.migrate' do
    let(:package)       { 'AuditLogTestPackage' }
    let(:root)          { Dir.mktmpdir('package-migration', Rails.root.join('tmp')) }
    let(:role)          { create(:role) }
    let(:migration_dir) { File.join(root, 'db/addon', package.underscore) }

    before do
      Setting.set('system_init_done', true)

      role

      FileUtils.mkdir_p(migration_dir)
      File.write(File.join(migration_dir, '20260101000000_audit_log_package_test.rb'), <<~MIGRATION)
        class AuditLogPackageTest < ActiveRecord::Migration[8.0]
          def self.up
            Role.find(#{role.id}).update!(name: 'Package Migrated')
          end

          def self.down
            Role.find(#{role.id}).update!(name: 'Package Reverted')
          end
        end
      MIGRATION

      allow(described_class).to receive(:root).and_return(root)
    end

    after do
      FileUtils.remove_entry(root)
    end

    it 'suppresses audit logging during package migrations', :aggregate_failures do
      expect { described_class.migrate(package) }
        .not_to change { AuditLog.where(auditable: role).count }

      expect(role.reload.name).to eq('Package Migrated')
    end

    it 'suppresses audit logging during package migration rollbacks', :aggregate_failures do
      described_class.migrate(package)
      expect(role.reload.name).to eq('Package Migrated')

      expect { described_class.migrate(package, 'reverse') }
        .not_to change { AuditLog.where(auditable: role).count }

      expect(role.reload.name).to eq('Package Reverted')
    end

    it 'restores audit logging after the package migration', :aggregate_failures do
      described_class.migrate(package)
      expect(role.reload.name).to eq('Package Migrated')

      expect { role.reload.update!(name: 'Audited') }
        .to change { AuditLog.where(auditable: role).count }.by(1)
    end
  end
end
