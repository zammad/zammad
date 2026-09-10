# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Tasks::Zammad::Package::UninstallDir do
  describe '.description' do
    it 'returns the description' do
      expect(described_class.description).to eq('Uninstall all Zammad addon packages from a directory in reverse dependency order')
    end
  end

  describe '.task_handler' do
    let(:directory) { Dir.mktmpdir('package-uninstall-dir-task', Rails.root.join('tmp')) }

    before do
      allow(ArgvHelper).to receive(:argv).and_return(argv)
      allow(Package).to receive(:uninstall_dir)
    end

    after do
      FileUtils.remove_entry(directory)
    end

    context 'without directory' do
      let(:argv) { %w[zammad:package:uninstall_dir] }

      it 'aborts with error' do
        expect { described_class.task_handler }
          .to raise_error(SystemExit)
          .and output(%r{Please provide a valid directory}).to_stderr
      end
    end

    context 'with missing directory' do
      let(:argv) { %w[zammad:package:uninstall_dir /nonexistent/directory] }

      it 'aborts with error' do
        expect { described_class.task_handler }
          .to raise_error(SystemExit)
          .and output(%r{Could not find directory}).to_stderr
      end
    end

    context 'with existing directory' do
      let(:argv) { ['zammad:package:uninstall_dir', directory] }

      it 'uninstalls all packages in the directory including their files', :aggregate_failures do
        expect { described_class.task_handler }.to output(%r{Uninstalling all packages in #{Regexp.escape(directory)}}).to_stdout
        expect(Package).to have_received(:uninstall_dir).with(directory, remove_files: true)
      end

      context 'when running in a container environment' do
        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('ZAMMAD_DOCKER').and_return('true')
        end

        it 'uninstalls all packages in the directory without touching the file system', :aggregate_failures do
          expect { described_class.task_handler }.to output(%r{done\.}).to_stdout
          expect(Package).to have_received(:uninstall_dir).with(directory, remove_files: false)
        end
      end
    end
  end
end
