# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

class SampleService
  def self.pre_run; end

  def initialize(manager:, fork_id: nil)
    # no-op
  end

  def run
    sleep 1
  end

  def self.service_name
    'Sample'
  end

  def self.skip?(manager:)
    false
  end

  def self.max_workers
    1
  end
end

class ProcessService < SampleService
  def run
    f = File.new self.class.path, 'w'
    f.write 'run'
    f.close
    sleep 1
  end

  def self.path
    Rails.root.join('tmp/process.service')
  end
end

RSpec.describe BackgroundServices do
  let(:instance) { described_class.new(config) }
  let(:config)   { [] }

  # Process stubs are reset before :ensure_threads_exited kills leftover threads, so these
  #   threads must not outlive their example and send real signals.
  def stop_threads(name)
    Thread.list.select { |thread| thread.name == name }.each { |thread| thread.kill.join }
  end

  describe '.available_services' do
    it 'matches existing classes' do
      expect(described_class.available_services).to contain_exactly(
        BackgroundServices::Service::ManageSessionsJobs,
        BackgroundServices::Service::ProcessScheduledJobs,
        BackgroundServices::Service::ProcessSessionsJobs,
        BackgroundServices::Service::ProcessDelayedCommunicationInboundJobs,
        BackgroundServices::Service::ProcessDelayedJobs,
        BackgroundServices::Service::ProcessDelayedAIJobs,
      )
    end
  end

  describe '#run', ensure_threads_exited: true do
    let(:config) { described_class::ServiceConfig.new(service: SampleService, disabled: false, workers: 0, worker_threads: 1) }

    it 'runs given services' do
      allow(instance).to receive(:run_service)
      instance.run
      expect(instance).to have_received(:run_service).with(config)
    end

    context 'when config has multiple services' do
      let(:forked)   { described_class::ServiceConfig.new(service: SampleService, disabled: false, workers: 3, worker_threads: 1) }
      let(:threaded) { described_class::ServiceConfig.new(service: SampleService, disabled: false, workers: 0, worker_threads: 1) }
      let(:config)   { [threaded, forked] }

      it 'runs forked services before threaded', aggregate_failures: true do
        allow(instance).to receive(:run_service)
        instance.run
        expect(instance).to have_received(:run_service).with(forked).ordered
        expect(instance).to have_received(:run_service).with(threaded).ordered
      end
    end

    context 'when the child process monitor reaped a child already' do
      let(:reaped_pid) { Process.fork { exit! }.tap { |pid| Process.wait(pid) } } # rubocop:disable Rails/Exit

      it 'still waits for the remaining children' do
        allow(instance).to receive_messages(run_service: nil, monitor_child_processes: nil)
        instance.child_pids = [reaped_pid]

        expect { instance.run }.not_to raise_error
      end
    end
  end

  describe '#run_service' do
    let(:config)      { described_class::ServiceConfig.new(service: SampleService, disabled: is_disabled, workers: workers_count, worker_threads: 1) }
    let(:is_disabled) { false }

    before do
      allow(instance).to receive(:start_as_forks)
      allow(instance).to receive(:start_as_thread)
    end

    shared_examples 'stops early if disabled' do
      context 'when disabled' do
        let(:is_disabled) { true }

        it 'stops early if disabled', :aggregate_failures do
          allow(Rails.logger).to receive(:info)
          instance.send(:run_service, config)

          expect(Rails.logger).to have_received(:info).with(no_args) do |&block|
            expect(block.call).to include('Skipping disabled service')
          end
        end
      end
    end

    shared_examples 'calls pre_run' do
      it 'calls pre_run' do
        allow(config.service).to receive(:pre_run)
        instance.send(:run_service, config)
        expect(config.service).to have_received(:pre_run)
      end
    end

    context 'when workers present' do
      let(:workers_count) { 1 }

      include_examples 'stops early if disabled'
      include_examples 'calls pre_run'

      it 'starts as fork' do
        instance.send(:run_service, config)
        expect(instance).to have_received(:start_as_forks).with(config.service, config.workers)
      end
    end

    context 'when workers not present' do
      let(:workers_count) { 0 }

      include_examples 'stops early if disabled'
      include_examples 'calls pre_run'

      it 'starts as thread' do
        instance.send(:run_service, config)
        expect(instance).to have_received(:start_as_thread).with(config.service)
      end
    end
  end

  describe '#start_as_forks' do
    context 'with a file check' do
      after do
        File.delete ProcessService.path
      end

      it 'runs Service#run' do
        instance.send(:start_as_forks, ProcessService, 1)
        Timeout.timeout(5) { sleep 0.1 until File.exist? ProcessService.path }

        expect(File.read(ProcessService.path)).to eq('run')
      end
    end

    it 'forks a new process' do
      process_pids = instance.send(:start_as_forks, SampleService, 1)

      Process.wait process_pids.first

      expect($CHILD_STATUS).to be_success
    end
  end

  describe '#start_as_thread', ensure_threads_exited: true do
    let(:config) { described_class::ServiceConfig.new(service: SampleService, disabled: false, workers: 0, worker_threads: 1) }

    context 'with logging' do
      let(:log) { [] }

      before do
        allow_any_instance_of(SampleService).to receive(:run) do
          log << :run_called
        end
      end

      it 'runs Service#run' do
        instance.send(:start_as_thread, SampleService)
        Timeout.timeout(5) { sleep 0.1 until log.any? }
        expect(log).to include(:run_called)
      end
    end

    it 'starts a new thread' do
      thread = instance.send(:start_as_thread, SampleService)
      expect(thread).to be_alive
    end
  end

  describe '#monitor_child_processes', ensure_threads_exited: true do
    let(:running_pid)  { Process.fork { sleep } }
    let(:died_pid)     { Process.fork { exit! } } # rubocop:disable Rails/Exit
    let(:kill_tracker) { { called: false } }

    before do
      stub_const("#{described_class}::CHILD_PROCESS_MONITOR_INTERVAL", 0.1)

      allow(Process).to receive(:kill).and_call_original
      allow(Process).to receive(:kill).with('TERM', Process.pid) { kill_tracker[:called] = true }

      # The died child is not the first one, so nothing has waited for it yet (zombie).
      instance.child_pids = [running_pid, died_pid]
      instance.send(:monitor_child_processes)

      deadline = 3.seconds.from_now
      sleep 0.05 until kill_tracker[:called] || Time.zone.now > deadline
    end

    after do
      stop_threads('child process monitoring')
      Process.kill('KILL', running_pid)
      Process.wait(running_pid)
    end

    it 'terminates the background worker if a child process died' do
      expect(Process).to have_received(:kill).with('TERM', Process.pid)
    end
  end

  describe '#handle_signal', ensure_threads_exited: true do
    let(:reaped_pid)  { 999_998 }
    let(:running_pid) { 999_999 }
    let(:calls)       { [] }

    before do
      stub_const("#{described_class}::SHUTDOWN_GRACE_PERIOD", 0)

      allow(Process).to receive(:kill) do |signal, pid|
        raise Errno::ESRCH if pid == reaped_pid

        calls << [signal, pid]
      end
      allow(Process).to receive(:exit!) { |status| calls << ['exit!', status] }

      # The child process monitor may have reaped an exited child already.
      instance.child_pids = [reaped_pid, running_pid]
      instance.send(:handle_signal, 'TERM')

      deadline = 3.seconds.from_now
      sleep 0.05 until calls.include?(['exit!', 1]) || Time.zone.now > deadline
    end

    after do
      stop_threads('shutdown handler')
      described_class.shutdown_requested = nil
    end

    it 'forces the termination of the remaining processes' do
      expect(calls).to include(['KILL', running_pid], ['KILL', Process.pid], ['exit!', 1])
    end
  end

  describe '#monitor_child_processes during a requested shutdown', ensure_threads_exited: true do
    before do
      stub_const("#{described_class}::CHILD_PROCESS_MONITOR_INTERVAL", 0.1)
      allow(Process).to receive(:kill)

      # The shutdown is requested while the monitor finds an exited child.
      allow(instance).to receive(:child_process_exited?) do
        described_class.shutdown_requested = true
        true
      end

      instance.child_pids = [Process.pid]
      instance.send(:monitor_child_processes).join(3)
    end

    after do
      stop_threads('child process monitoring')
      described_class.shutdown_requested = nil
    end

    it 'does not terminate the background worker once more' do
      expect(Process).not_to have_received(:kill)
    end
  end

  # The file watcher thread must not survive the examples: it would keep polling all watchable
  #   paths for the rest of the suite and crash unrelated examples when a file it just globbed
  #   is removed again (e.g. by the package specs).
  describe '#restart_on_file_change', ensure_threads_exited: true do
    let(:config)       { described_class::ServiceConfig.new(service: SampleService, disabled: false, workers: 0, worker_threads: 1) }
    let(:kill_tracker) { { called: false } }

    before do
      stub_const("#{described_class}::FILE_WATCHING_INTERVAL", 0)

      allow(Process).to receive(:kill) { kill_tracker[:called] = true }
      allow(Rails.application.config).to receive(:reloading_enabled?).and_return(true)

      instance.run

      FileUtils.touch(file)

      # The file-watcher notices changes on its own background thread, so give it a real
      #   chance to run instead of racing a fixed sleep against CI scheduling delays - for
      #   the negative case, this also means waiting out the same budget without success.
      deadline = 3.seconds.from_now
      sleep 0.05 until kill_tracker[:called] || Time.zone.now > deadline
    end

    context 'when backend file changes' do
      let(:file) { 'app/models/user.rb' }

      it 'stops' do
        expect(Process).to have_received(:kill).with('TERM', anything)
      end
    end

    context 'when frontend file changes' do
      let(:file) { 'app/frontend/apps/desktop/AppDesktop.vue' }

      it 'does not stop' do
        expect(Process).not_to have_received(:kill)
      end
    end
  end
end
