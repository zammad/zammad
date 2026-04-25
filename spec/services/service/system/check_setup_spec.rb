# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::System::CheckSetup, :aggregate_failures do

  describe '.new?' do
    context 'with fresh install' do
      before do
        Setting.set('system_init_done', false)
      end

      it 'returns true' do
        expect(described_class.new?).to be(true)
      end
    end

    context 'with in progress setup' do
      before do
        Setting.set('system_init_done', false)
        Setting.set('import_mode', true)
      end

      it 'returns false' do
        expect(described_class.new?).to be(false)
      end
    end

    context 'with finished setup' do
      before do
        Setting.set('system_init_done', true)
        create(:admin)
      end

      it 'returns false' do
        expect(described_class.new?).to be(false)
      end
    end
  end

  describe '.new!' do
    context 'with fresh install' do
      before do
        Setting.set('system_init_done', false)
      end

      it 'raises no error' do
        expect { described_class.new! }.not_to raise_error
      end
    end

    context 'with in progress setup' do
      before do
        Setting.set('system_init_done', false)
        Setting.set('import_mode', true)
      end

      it 'raises error' do
        expect { described_class.new! }.to raise_error(Service::System::CheckSetup::SystemSetupError)
      end
    end

    context 'with finished setup' do
      before do
        Setting.set('system_init_done', true)
        create(:admin)
      end

      it 'raises error' do
        expect { described_class.new! }.to raise_error(Service::System::CheckSetup::SystemSetupError)
      end
    end
  end

  describe '.done?' do
    context 'with fresh install' do
      before do
        Setting.set('system_init_done', false)
      end

      it 'returns false' do
        expect(described_class.done?).to be(false)
      end
    end

    context 'with in progress setup' do
      before do
        Setting.set('system_init_done', false)
        Setting.set('import_mode', true)
      end

      it 'returns false' do
        expect(described_class.done?).to be(false)
      end
    end

    context 'with finished setup' do
      before do
        Setting.set('system_init_done', true)
        create(:admin)
      end

      it 'returns true' do
        expect(described_class.done?).to be(true)
      end
    end
  end

  describe '.done!' do
    context 'with fresh install' do
      before do
        Setting.set('system_init_done', false)
      end

      it 'raises error' do
        expect { described_class.done! }.to raise_error(Service::System::CheckSetup::SystemSetupError)
      end
    end

    context 'with in progress setup' do
      before do
        Setting.set('system_init_done', false)
        Setting.set('import_mode', true)
      end

      it 'raises error' do
        expect { described_class.done! }.to raise_error(Service::System::CheckSetup::SystemSetupError)
      end
    end

    context 'with finished setup' do
      before do
        Setting.set('system_init_done', true)
        create(:admin)
      end

      it 'raises no error' do
        expect { described_class.done! }.not_to raise_error
      end
    end
  end

  describe '#execute' do
    subject(:service_result) { described_class.new.tap(&:execute) }

    describe 'with fresh install' do
      before do
        Setting.set('system_init_done', false)
        allow(AutoWizard).to receive(:enabled?).and_return(auto_wizard_enabled)
        service_result
      end

      context 'when auto wizard is not enabled' do
        let(:auto_wizard_enabled) { false }

        it 'returns new status' do
          expect(service_result.status).to eq('new')
          expect(service_result.type).to be_nil
        end
      end

      context 'when auto wizard is enabled' do
        let(:auto_wizard_enabled) { true }

        it 'returns automated status' do
          expect(service_result.status).to eq('automated')
          expect(service_result.type).to be_nil
        end
      end
    end

    context 'with finished setup' do
      before do
        Setting.set('system_init_done', true)
        create(:admin)
      end

      context 'with manual setup' do
        before do
          Setting.set('import_mode', false)
          service_result
        end

        it 'returns done status' do
          expect(service_result.status).to eq('done')
          expect(service_result.type).to be_nil
        end
      end

      context 'with auto setup' do
        before do
          Setting.set('import_mode', false)
          allow(AutoWizard).to receive(:enabled?).and_return(true)
          service_result
        end

        it 'returns done status' do
          expect(service_result.status).to eq('done')
          expect(service_result.type).to be_nil
        end
      end

      context 'with import setup' do
        before do
          Setting.set('import_mode', true)
          service_result
        end

        it 'returns done status' do
          expect(service_result.status).to eq('in_progress')
          expect(service_result.type).to eq('import')
        end
      end
    end

    describe 'with in progress setup' do
      before do
        Setting.set('system_init_done', false)
      end

      context 'with manual setup' do
        before do
          Setting.set('import_mode', false)

          Service::ExecuteLockedBlock.execute('Zammad::System::Setup', 10_000) do
            service_result
          end
        end

        it 'returns in_progress status' do
          expect(service_result.status).to eq('in_progress')
          expect(service_result.type).to eq('manual')
        end
      end

      context 'with auto setup' do
        before do
          Setting.set('import_mode', false)

          Service::ExecuteLockedBlock.execute('Zammad::System::Setup', 10_000) do
            begin
              json = Rails.root.join('auto_wizard.json')
              FileUtils.touch(json)
              service_result
            ensure
              FileUtils.rm(json)
            end
          end
        end

        it 'returns in_progress status' do
          expect(service_result.status).to eq('in_progress')
          expect(service_result.type).to eq('auto')
        end
      end

      context 'with import setup' do
        before do
          Setting.set('import_mode', true)

          service_result
        end

        it 'returns in_progress status' do
          expect(service_result.status).to eq('in_progress')
          expect(service_result.type).to eq('import')
        end
      end
    end

    describe 'dubious setup' do
      context 'with finished setup and no admin user' do
        before do
          Setting.set('system_init_done', true)
        end

        it 'raises error' do
          expect { service_result }.to raise_error(Service::System::CheckSetup::SystemSetupError)
        end
      end

      context 'with not finished setup and at least one admin users' do
        before do
          Setting.set('system_init_done', false)
          create(:admin)
        end

        it 'raises error' do
          allow(Rails.logger).to receive(:warn)
          service_result
          expect(Rails.logger).to have_received(:warn).with('The system setup is not marked as done, but at least one admin user is existing. Marking system setup as done.')
        end
      end
    end
  end
end
