# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Zammad::DB::MaxConnections do
  describe '#calculate' do
    before do
      allow(ActiveRecord::Base.connection_pool).to receive(:size).and_return(5)
      allow(ENV).to receive(:[]).and_call_original
    end

    context 'when no extra ENV variables' do
      before do
        allow($stdin).to receive(:gets).and_return("2\n", "0\n", "0\n")
      end

      it 'returns correct amount' do
        expect(described_class.new.calculate).to eq(20)
      end

      it 'prints questions' do
        expect { described_class.new.calculate }.to output(%r{How many}).to_stdout
      end

      it 'prints result' do
        expect { described_class.new.calculate }.to output(%r{max_connections value: 20}).to_stdout
      end

      it 'returns correct amount with WEB_CONCURRENCY=0' do
        allow(ENV).to receive(:[]).with('WEB_CONCURRENCY').and_return('0')
        expect(described_class.new.calculate).to eq(20)
      end

      it 'returns correct amount with WEB_CONCURRENCY=1' do
        allow(ENV).to receive(:[]).with('WEB_CONCURRENCY').and_return('1')
        expect(described_class.new.calculate).to eq(20)
      end

      it 'returns correct amount with WEB_CONCURRENCY=2' do
        allow(ENV).to receive(:[]).with('WEB_CONCURRENCY').and_return('2')
        expect(described_class.new.calculate).to eq(30)
      end
    end

    context 'when relying on default values' do
      before do
        allow($stdin).to receive(:gets).and_return("\n", "\n", "\n")
      end

      it 'returns correct amount with single web server/pod' do
        allow(ENV).to receive(:[]).with('WEB_CONCURRENCY').and_return('1')
        expect(described_class.new.calculate).to eq(15)
      end
    end

    context 'with invalid input' do
      before do
        allow($stdin).to receive(:gets).and_return("foobar\n", "2\n", "0\n", "0\n")
      end

      it 're-prompts on invalid input' do
        expect(described_class.new.calculate).to eq(20)
      end
    end

    context 'with extra ENV variables' do
      before do
        allow(ENV).to receive(:[]).with('ZAMMAD_MAX_CONNECTIONS_WEB_SERVERS').and_return('3')
        allow(ENV).to receive(:[]).with('ZAMMAD_MAX_CONNECTIONS_CONCURRENT_CRONJOBS').and_return('1')
        allow(ENV).to receive(:[]).with('ZAMMAD_MAX_CONNECTIONS_CONCURRENT_MANUAL').and_return('0')
      end

      it 'returns correct amount' do
        expect(described_class.new.calculate).to eq(30)
      end

      it 'does not print questions' do
        expect { described_class.new.calculate }.not_to output(%r{How many}).to_stdout
      end

      it 'prints result' do
        expect { described_class.new.calculate }.to output(%r{max_connections value: 30}).to_stdout
      end
    end

    context 'with invalid extra ENV variables' do
      before do
        allow(ENV).to receive(:[]).with('ZAMMAD_MAX_CONNECTIONS_WEB_SERVERS').and_return('foobar')
        allow(ENV).to receive(:[]).with('ZAMMAD_MAX_CONNECTIONS_CONCURRENT_CRONJOBS').and_return('1')
        allow(ENV).to receive(:[]).with('ZAMMAD_MAX_CONNECTIONS_CONCURRENT_MANUAL').and_return('0')
        allow($stdin).to receive(:gets).and_return("2\n", "0\n", "0\n")
      end

      it 'prompts for valid input instead' do
        expect(described_class.new.calculate).to eq(25)
      end
    end
  end
end
