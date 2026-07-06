# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Tasks::Zammad::Package::InstallApi do
  describe '.description' do
    it 'returns the description' do
      expect(described_class.description).to eq('Install packages remotely via API to a certain version.')
    end
  end

  describe '.task_handler' do
    before do
      allow(ArgvHelper).to receive(:argv).and_return(argv)
      allow(Package).to receive_messages(api_token: token, api_packages: api_packages)
    end

    let(:token)        { 'secret' }
    let(:api_packages) { [] }

    context 'with invalid version name' do
      let(:argv) { %w[zammad:package:install_api all invalid dry] }

      it 'aborts with error' do
        expect { described_class.task_handler }
          .to raise_error(SystemExit)
          .and output("Error: Invalid parameter version name 'invalid'!\n").to_stderr
      end
    end

    context 'with invalid execution mode' do
      let(:argv) { %w[zammad:package:install_api all 7.0.x execute] }

      it 'aborts with error' do
        expect { described_class.task_handler }
          .to raise_error(SystemExit)
          .and output("Error: Invalid parameter execution mode 'execute'!\n").to_stderr
      end
    end

    context 'without token' do
      let(:argv)  { %w[zammad:package:install_api all 7.0.x dry] }
      let(:token) { nil }

      it 'aborts with hint' do
        expect { described_class.task_handler }
          .to raise_error(SystemExit)
          .and output(%r{Please set a token}).to_stderr
      end
    end

    context 'with valid arguments in dry mode' do
      let(:argv) { %w[zammad:package:install_api all 7.0.x dry] }
      let(:api_packages) do
        [{ 'name' => 'TestPackage', 'version' => '7.0.1' }]
      end

      it 'does not call Package.install', :aggregate_failures do
        allow(Package).to receive(:install)
        expect { described_class.task_handler }.to output(%r{dry mode}).to_stdout
        expect(Package).not_to have_received(:install)
      end
    end

    context 'with valid arguments in prod mode' do
      let(:argv) { %w[zammad:package:install_api all 7.0.x prod] }
      let(:api_packages) do
        [{ 'name' => 'TestPackage', 'version' => '7.0.1' }]
      end

      before { allow(Package).to receive(:find_by).and_return(nil) }

      it 'calls Package.install and outputs progress', :aggregate_failures do
        allow(Package).to receive(:install)
        expect { described_class.task_handler }
          .to output(%r{Installing TestPackage 7\.0\.1}).to_stdout
        expect(Package).to have_received(:install).with(string: api_packages.first.to_json)
      end
    end

    context 'when package is already up-to-date' do
      let(:argv) { %w[zammad:package:install_api all 7.0.x prod] }
      let(:api_packages) do
        [{ 'name' => 'TestPackage', 'version' => '7.0.1' }]
      end
      let(:existing) { instance_double(Package, version: '7.0.1') }

      before { allow(Package).to receive(:find_by).and_return(existing) }

      it 'skips the package' do
        allow(Package).to receive(:install)
        described_class.task_handler
        expect(Package).not_to have_received(:install)
      end
    end

    context 'when filtering by package name' do
      let(:argv) { %w[zammad:package:install_api OtherPackage 7.0.x prod] }
      let(:api_packages) do
        [{ 'name' => 'TestPackage', 'version' => '7.0.1' }]
      end

      before { allow(Package).to receive(:find_by).and_return(nil) }

      it 'skips packages that do not match' do
        allow(Package).to receive(:install)
        described_class.task_handler
        expect(Package).not_to have_received(:install)
      end
    end
  end
end
