# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Tasks::Zammad::Store::MoveFiles do
  describe '.description' do
    it 'returns the description' do
      expect(described_class.description).to eq('Move files/attachments from one store provider to another.')
    end
  end

  describe '.usage' do
    it 'returns the usage' do
      expect(described_class.usage).to eq('Usage: bundle exec rails zammad:store:move_files <source> <target>')
    end
  end

  describe '.handle_argv' do
    it 'returns the source and target' do
      allow(ArgvHelper).to receive(:argv).and_return(%w[zammad:store:move_files File S3])

      expect(described_class.handle_argv).to eq(%w[File S3])
    end

    context 'when a provider is not found' do
      it 'warns and exits', :aggregate_failures do
        allow(ArgvHelper).to receive(:argv).and_return(%w[zammad:store:move_files NFS S3])

        expect { described_class.handle_argv }.to raise_error(SystemExit)
          .and output("Store provider 'NFS' not found.\n").to_stderr
      end
    end
  end

  describe '.task_handler' do
    let(:source) { 'File' }
    let(:target) { 'S3' }

    before do
      allow(described_class).to receive(:handle_argv).and_return([source, target])
      allow(Store::File).to receive(:move).with(source, target).and_return(status)
    end

    context 'when status is true' do
      let(:status) { true }

      it 'outputs the message' do
        expect { described_class.task_handler }.to output("Moving files from #{source} to #{target}...\nDone.\n").to_stdout
      end
    end

    context 'when status is false' do
      let(:status) { false }

      it 'warns and exits' do
        expect { described_class.task_handler }.to output("Moving files from #{source} to #{target}...\nDone.\n").to_stdout
          .and raise_error(SystemExit)
          .and output("One or more files could not be moved. For further information, please check the logs.\n").to_stderr
      end
    end
  end
end
