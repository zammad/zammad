# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/import_job_backend_examples'

RSpec.describe Import::Ldap, sequencer: :caller do
  it_behaves_like 'ImportJob backend'

  describe '.queueable?' do

    it 'is queueable if LDAP integration is activated and configured' do
      allow(Setting).to receive(:get).with('ldap_integration').and_return(true)
      allow(Setting).to receive(:get).with('ldap_config').and_return({ host: 'some' })
      expect(described_class.queueable?).to be true
    end

    it "isn't queueable if LDAP integration is deactivated" do
      allow(Setting).to receive(:get).with('ldap_integration').and_return(false)
      allow(Setting).to receive(:get).with('ldap_config').and_return({ host: 'some' })
      expect(described_class.queueable?).to be false
    end

    it "isn't queueable if LDAP configuration is missing" do
      allow(Setting).to receive(:get).with('ldap_integration').and_return(true)
      allow(Setting).to receive(:get).with('ldap_config').and_return({})
      expect(described_class.queueable?).to be false
    end
  end

  describe '#start' do
    it 'starts LDAP import resource factories' do
      import_job = create(:import_job)
      instance   = described_class.new(import_job)

      allow(Setting).to receive(:get).with('ldap_integration').and_return(true)
      allow(Setting).to receive(:get).with('ldap_config').and_return(true)

      expect_sequence

      instance.start
    end

    context 'requirements' do

      it 'lets dry runs always start' do
        import_job = create(:import_job, dry_run: true)
        instance   = described_class.new(import_job)

        expect_sequence

        instance.start
      end

      it 'informs about deactivated ldap_integration' do
        import_job = create(:import_job)
        instance   = described_class.new(import_job)

        allow(Setting).to receive(:get).with('ldap_integration').and_return(false)

        expect_no_sequence

        expect do
          instance.start
          import_job.reload
        end.to change {
          import_job.result
        }

        expect(import_job.result.key?(:info)).to be true
      end

      it 'informs about blank ldap_config' do
        import_job = create(:import_job)
        instance   = described_class.new(import_job)

        allow(Setting).to receive(:get).with('ldap_integration').and_return(true)
        allow(Setting).to receive(:get).with('ldap_config').and_return({})

        expect_no_sequence

        expect do
          instance.start
          import_job.reload
        end.to change {
          import_job.result
        }

        expect(import_job.result.key?(:info)).to be true
      end
    end
  end

  describe '#reschedule?' do

    it 'initiates always a rescheduling' do
      import_job  = create(:import_job)
      instance    = described_class.new(import_job)
      delayed_job = double()

      expect(instance.reschedule?(delayed_job)).to be true
    end

    it 'updates the result with an info text' do
      import_job  = create(:import_job)
      instance    = described_class.new(import_job)
      delayed_job = double()

      expect do
        instance.reschedule?(delayed_job)
      end.to change {
        import_job.result
      }

      expect(import_job.result.key?(:info)).to be true
    end

  end
end
