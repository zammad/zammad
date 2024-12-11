# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe BackgroundServices::Service::ManageSessionsJobs do
  let(:manager) { BackgroundServices.new(BackgroundServices::ServiceConfig.configuration_from_env(env)) }
  let(:env)     { {} }

  describe '.skip?' do
    context 'when ProcessSessionsJob is missing' do
      let(:manager) { BackgroundServices.new([]) }

      it 'skips' do
        expect(described_class.skip?(manager:)).to be(true)
      end
    end

    context 'when ProcessSessionsJob is disabled' do
      let(:env) do
        {
          'ZAMMAD_PROCESS_SESSIONS_JOBS_DISABLE' => 'true',
          'ZAMMAD_PROCESS_SESSIONS_JOBS_WORKERS' => '2',
        }
      end

      it 'skips' do
        expect(described_class.skip?(manager:)).to be(true)
      end
    end

    context 'when ProcessSessionsJob is active and threaded (default)' do
      it 'skips' do
        expect(described_class.skip?(manager:)).to be(true)
      end
    end

    context 'when ProcessSessionsJob is active and forking' do
      let(:env) { { 'ZAMMAD_PROCESS_SESSIONS_JOBS_WORKERS' => '2' } }

      it 'skips' do
        expect(described_class.skip?(manager:)).to be(false)
      end
    end
  end
end
