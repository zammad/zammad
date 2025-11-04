# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Zammad::Service::Redis, :aggregate_failures do
  before do
    allow(ENV).to receive(:[]) do |key|
      env[key]
    end
  end

  let(:env) { {} }

  describe '.config' do
    context 'without any ENV vars set' do
      it 'returns the default standalone config' do
        expect(described_class.config).to eq(
          driver: :hiredis,
          url:    'redis://localhost:6379'
        )
      end
    end

    context 'with standalone Redis' do

      context 'with REDIS_URL set to a non-TLS URL' do
        let(:env) { { 'REDIS_URL' => 'redis://redis.example.com:1234' } }

        it 'returns the standalone config with the given URL and hiredis driver' do
          expect(described_class.config).to eq(
            driver: :hiredis,
            url:    'redis://redis.example.com:1234'
          )
        end
      end

      context 'with REDIS_URL set to a TLS URL' do
        let(:env) { { 'REDIS_URL' => 'rediss://redis.example.com:1234' } }

        it 'returns the standalone config with the given URL and ruby driver' do
          expect(described_class.config).to eq(
            driver: :ruby,
            url:    'rediss://redis.example.com:1234'
          )
        end
      end
    end

    context 'with Redis Sentinel' do
      let(:env) do
        {
          'REDIS_SENTINELS'         => 'sentinel1.example.com:26380, sentinel2.example.com',
          'REDIS_SENTINEL_NAME'     => 'custommaster',
          'REDIS_SENTINEL_USERNAME' => 'sentineluser',
          'REDIS_SENTINEL_PASSWORD' => 'sentinelpass',
          'REDIS_USERNAME'          => 'user',
          'REDIS_PASSWORD'          => 'pass'
        }
      end

      it 'returns the sentinel config with the given parameters' do
        expect(described_class.config).to eq(
          driver:            :hiredis,
          name:              'custommaster',
          role:              :master,
          sentinels:         [
            { host: 'sentinel1.example.com', port: 26_380 },
            { host: 'sentinel2.example.com', port: 26_379 }
          ],
          sentinel_username: 'sentineluser',
          sentinel_password: 'sentinelpass',
          username:          'user',
          password:          'pass',
        )
      end

      context 'without optional ENV vars set' do
        let(:env) { { 'REDIS_SENTINELS' => 'sentinel1.example.com' } }

        it 'returns the sentinel config with default values for optional parameters' do
          expect(described_class.config).to eq(
            driver:    :hiredis,
            name:      'mymaster',
            role:      :master,
            sentinels: [
              { host: 'sentinel1.example.com', port: 26_379 }
            ]
          )
        end
      end

    end
  end
end
