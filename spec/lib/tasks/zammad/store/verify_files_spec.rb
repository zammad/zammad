# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Tasks::Zammad::Store::VerifyFiles do
  describe '.description' do
    it 'returns the description' do
      expect(described_class.description).to eq('Verify files/attachments checksums.')
    end
  end

  describe '.usage' do
    it 'returns the usage' do
      expect(described_class.usage).to eq('Usage: bundle exec rails zammad:store:verify_files')
    end
  end

  describe '.task_handler' do
    before do
      allow(Store::File).to receive(:verify).and_return(status)
    end

    context 'when status is true' do
      let(:status) { true }

      it 'outputs the message' do
        expect { described_class.task_handler }.to output("Verifying files checksums...\nDone.\n").to_stdout
      end
    end

    context 'when status is false' do
      let(:status) { false }

      it 'warns and exits' do
        expect { described_class.task_handler }.to output("Verifying files checksums...\nDone.\n").to_stdout
          .and raise_error(SystemExit)
          .and output("One or more files could not be verified. For further information, please check the logs.\n").to_stderr
      end
    end
  end
end
