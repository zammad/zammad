# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Tasks::Zammad::Package::Precompile do
  describe '.description' do
    it 'returns the description' do
      expect(described_class.description).to eq('Execute all package related precompilations.')
    end
  end

  describe '.task_handler' do
    let(:commands) { [] }

    before do
      allow(described_class).to receive(:exec_command) { |cmd| commands << cmd }
      allow(described_class).to receive(:set_default_umask)
      allow(Package).to receive(:app_package_installation?).and_return(app_package_installation)
    end

    context 'with package installation' do
      let(:app_package_installation) { true }

      it 'sets up the javascript environment before the asset precompile', :aggregate_failures do
        expect { described_class.task_handler }.to output(%r{done\.}).to_stdout
        expect(commands).to eq(
          [
            'zammad run pnpm install --production=false --config.confirm-modules-purge=false',
            'zammad run pnpm run generate-setting-types',
            'ZAMMAD_GRAPHQL_INTROSPECTION=true zammad run pnpm run generate-graphql-api',
            'zammad run bundle exec vite clobber',
            'zammad run rake assets:precompile',
          ]
        )
      end
    end

    context 'with source installation' do
      let(:app_package_installation) { false }

      it 'sets up the javascript environment before the asset precompile', :aggregate_failures do
        expect { described_class.task_handler }.to output(%r{done\.}).to_stdout
        expect(commands).to eq(
          [
            'pnpm install --production=false --config.confirm-modules-purge=false',
            'pnpm run generate-setting-types',
            'ZAMMAD_GRAPHQL_INTROSPECTION=true pnpm run generate-graphql-api',
            'bundle exec vite clobber',
            'rake assets:precompile',
          ]
        )
      end
    end
  end
end
