# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ImportJob do

  before do
    stub_const test_backend_name, test_backend_class
    stub_const test_backend_noreschedule_name, test_backend_noreschedule_class
  end

  let(:test_backend_name) { 'Import::Test' }
  let(:test_backend_class) do
    Class.new(Import::Base) do
      def start
        @import_job.result = { state: 'Done' }
      end
    end
  end

  let(:test_backend_noreschedule_name) { 'Import::NoRescheduleMethod' }
  let(:test_backend_noreschedule_class) do
    Class.new do
      def initialize(import_job)
        @import_job = import_job
      end

      def start
        @import_job.result = { state: 'Done' }
      end

      def reschedule?(_delayed_job)
        'invalid_but_checkable_result'
      end
    end
  end

  describe '#dry_run' do

    it 'starts delayed dry run import job' do
      expect do
        described_class.dry_run(
          name:    test_backend_name,
          payload: {}
        )
      end.to change(Delayed::Job, :count).by(1)
    end

    it 'starts dry run import job immediately' do
      expect do
        described_class.dry_run(
          name:    test_backend_name,
          payload: {},
          delay:   false
        )
      end.not_to change(Delayed::Job, :count)
    end

    it "doesn't start job if one exists" do

      create(:import_job, dry_run: true)

      expect do
        described_class.dry_run(
          name:    test_backend_name,
          payload: {},
        )
      end.not_to change(Delayed::Job, :count)
    end

  end

  describe '#queue_registered' do

    it 'queues registered import jobs' do
      allow(Setting).to receive(:get)
      allow(Setting).to receive(:get).with('import_backends').and_return([test_backend_name])

      expect do
        described_class.queue_registered
      end.to change {
        described_class.exists?(name: test_backend_name)
      }
    end

    it "doesn't queue if backend isn't #queueable?" do
      allow(Setting).to receive(:get)
      allow(Setting).to receive(:get).with('import_backends').and_return([test_backend_name])
      allow(test_backend_class).to receive(:queueable?).and_return(false)

      expect do
        described_class.queue_registered
      end.not_to change {
        described_class.exists?(name: test_backend_name)
      }
    end

    it "doesn't queue if unfinished job entries exist" do
      create(:import_job)

      allow(Setting).to receive(:get)
      allow(Setting).to receive(:get).with('import_backends').and_return([test_backend_name])

      expect do
        described_class.queue_registered
      end.not_to change {
        described_class.exists?(name: test_backend_name)
      }
    end

    it 'queues if only an unfinished dry run exists' do
      create(:import_job, :interrupted, dry_run: true)

      allow(Setting).to receive(:get)
      allow(Setting).to receive(:get).with('import_backends').and_return([test_backend_name])

      expect do
        described_class.queue_registered
      end.to change {
        described_class.exists?(name: test_backend_name, dry_run: false)
      }
    end

    it 'logs errors for invalid registered backends' do
      allow(Setting).to receive(:get)
      allow(Setting).to receive(:get).with('import_backends').and_return(['InvalidBackend'])

      allow(described_class.logger).to receive(:error)
      described_class.queue_registered
      expect(described_class.logger).to have_received(:error)
    end

  end

  describe '#sync_pending?' do
    it 'is true for a queued sync' do
      create(:import_job, name: test_backend_name)

      expect(described_class).to be_sync_pending(test_backend_name)
    end

    it 'is true for an unfinished sync' do
      create(:import_job, :interrupted, name: test_backend_name)

      expect(described_class).to be_sync_pending(test_backend_name)
    end

    it 'is false for a finished sync' do
      create(:import_job, name: test_backend_name, started_at: 1.hour.ago, finished_at: 1.hour.ago)

      expect(described_class).not_to be_sync_pending(test_backend_name)
    end

    it 'is false for an unfinished dry run' do
      create(:import_job, :interrupted, name: test_backend_name, dry_run: true)

      expect(described_class).not_to be_sync_pending(test_backend_name)
    end
  end

  describe '#cleanup_import_jobs' do
    let(:cleanup_started_at) { Time.zone.now }

    it 'marks interrupted import jobs as finished' do
      job = create(:import_job, :interrupted)

      expect { described_class.cleanup_import_jobs(cleanup_started_at) }
        .to change { job.reload.finished_at }.from(nil)
    end

    it 'marks interrupted dry runs as finished' do
      job = create(:import_job, :interrupted, dry_run: true)

      expect { described_class.cleanup_import_jobs(cleanup_started_at) }
        .to change { job.reload.finished_at }.from(nil)
    end

    it 'stores the interruption as an error in the result' do
      job = create(:import_job, :interrupted, dry_run: true)

      described_class.cleanup_import_jobs(cleanup_started_at)

      expect(job.reload.result[:error]).to be_present
    end

    it "doesn't touch jobs that were updated since the cleanup started" do
      job = create(:import_job, :interrupted, updated_at: cleanup_started_at + 1.second)

      expect { described_class.cleanup_import_jobs(cleanup_started_at) }
        .not_to change { job.reload.finished_at }
    end

    it "doesn't touch jobs that were not started yet" do
      job = create(:import_job, updated_at: 2.days.ago)

      expect { described_class.cleanup_import_jobs(cleanup_started_at) }
        .not_to change { job.reload.finished_at }
    end
  end

  describe '#running' do
    it "doesn't contain dry runs" do
      create(:import_job, :interrupted, dry_run: true)

      expect(described_class.running).to be_empty
    end

    it 'contains unfinished import jobs' do
      job = create(:import_job, :interrupted)

      expect(described_class.running).to contain_exactly(job)
    end
  end

  describe '#start' do

    it 'starts queued import jobs' do
      create_list(:import_job, 2)

      expect do
        described_class.start
      end.to change {
        described_class.where(started_at: nil).count
      }.by(-2)
    end

    it "doesn't start queued dry run import jobs" do
      create_list(:import_job, 2)
      create(:import_job, dry_run: true)

      expect do
        described_class.start
      end.to change {
        described_class.where(started_at: nil).count
      }.by(-2)
    end
  end

  describe '#start_registered' do
    it 'queues and starts registered import backends' do
      allow(Setting).to receive(:get)
      allow(Setting).to receive(:get).with('import_backends').and_return([test_backend_name])

      expect do
        described_class.start_registered
      end.to change {
        described_class.where.not(started_at: nil).where.not(finished_at: nil).count
      }.by(1)
    end
  end

  describe '#backend_valid?' do

    it 'detects existing backends' do
      expect(described_class.backend_valid?(test_backend_name)).to be true
    end

    it 'detects not existing backends' do
      expect(described_class.backend_valid?('InvalidBackend')).to be false
    end
  end

  describe '#backends' do

    it 'returns list of backend namespaces' do
      allow(Setting).to receive(:get).with('import_backends').and_return(['Import::Ldap'])
      allow(Import::Ldap).to receive(:active?).and_return(true)

      backends = described_class.backends

      expect(backends).to be_a(Array)
      expect(backends).not_to be_blank
    end

    it 'returns blank array if none are found' do
      allow(Setting).to receive(:get).with('import_backends')

      expect(described_class.backends).to eq([])
    end

    it "doesn't return invalid backends" do
      allow(Setting).to receive(:get).with('import_backends').and_return(['Import::InvalidBackend'])

      expect(described_class.backends).to eq([])
    end

    it "doesn't return inactive backends" do
      allow(Setting).to receive(:get).with('import_backends').and_return(['Import::Ldap'])
      allow(Import::Ldap).to receive(:active?).and_return(false)

      expect(described_class.backends).to eq([])
    end
  end

  describe '.start' do

    it 'runs import backend and updates started_at and finished_at' do

      instance = create(:import_job)

      expect do
        instance.start
      end.to change {
        instance.started_at
      }.and change {
        instance.finished_at
      }.and change {
        instance.result
      }
    end

    it 'handles exceptions as errors' do

      instance = create(:import_job)

      error_message = 'Some horrible error'
      allow_any_instance_of(test_backend_class).to receive(:start).and_raise(error_message)

      expect do
        instance.start
        instance.reload
      end.to change {
        instance.started_at
      }.and change {
        instance.finished_at
      }.and change {
        instance.result
      }

      expect(instance.result[:error]).to eq(error_message)
    end
  end

  describe '.reschedule?' do

    it 'returns false for already finished jobs' do
      instance    = create(:import_job)
      delayed_job = double

      instance.update!(finished_at: Time.zone.now)

      expect(instance.reschedule?(delayed_job)).to be false
    end

    it 'returns false for backends not responding to reschedule?' do
      instance    = create(:import_job)
      delayed_job = double

      expect(instance.reschedule?(delayed_job)).to be false
    end

    it 'returns the backend reschedule? value' do
      instance    = create(:import_job, name: 'Import::NoRescheduleMethod')
      delayed_job = double

      expect(instance.reschedule?(delayed_job)).to eq 'invalid_but_checkable_result'
    end
  end
end
