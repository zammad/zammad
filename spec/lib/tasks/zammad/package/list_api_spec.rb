# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Tasks::Zammad::Package::ListApi do
  describe '.description' do
    it 'returns the description' do
      expect(described_class.description).to eq('List packages remotely via API to a certain version.')
    end
  end

  describe '.task_handler' do
    before do
      allow(Package).to receive_messages(api_token: token, api_packages: api_packages)
    end

    let(:token)        { 'secret' }
    let(:api_packages) { [] }

    context 'without token' do
      let(:token) { nil }

      it 'aborts with hint' do
        expect { described_class.task_handler }
          .to raise_error(SystemExit)
          .and output(%r{Please set a token}).to_stderr
      end
    end

    context 'with no packages available' do
      it 'outputs only the header' do
        expect { described_class.task_handler }
          .to output(%r{Package.*Version.*Installed.*Newest}).to_stdout
      end
    end

    context 'with a package that is not installed' do
      let(:api_packages) { [{ 'name' => 'TestPackage', 'version' => '7.0.1' }] }

      before { allow(Package).to receive(:find_by).and_return(nil) }

      it 'shows the package as not installed' do
        expect { described_class.task_handler }
          .to output(%r{TestPackage.*No.*7.0.1}).to_stdout
      end
    end

    context 'with a package that is installed' do
      let(:api_packages) { [{ 'name' => 'TestPackage', 'version' => '7.0.2' }] }
      let(:existing) { instance_double(Package, version: '7.0.1') }

      before do
        allow(Package).to receive(:find_by).and_return(existing)
        allow(existing).to receive(:[]).with('version').and_return('7.0.1')
      end

      it 'shows the installed version and newest version' do
        expect { described_class.task_handler }
          .to output(%r{TestPackage.*7.0.1.*Yes.*7.0.2}).to_stdout
      end
    end
  end
end
