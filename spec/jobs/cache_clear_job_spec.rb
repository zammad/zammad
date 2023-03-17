# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CacheClearJob do
  around do |example|
    old_cache = Rails.cache

    Rails.cache = cache

    example.run
  ensure
    Rails.cache = old_cache
  end

  before do
    allow(Rails.cache).to receive(:cleanup).and_call_original
  end

  context 'when Cache is FileStore' do
    let(:cache) { ActiveSupport::Cache::FileStore.new 'path' }

    it 'does cleanup' do
      described_class.perform_now
      expect(Rails.cache).to have_received :cleanup
    end
  end

  context 'when Cache is Memcached' do
    let(:cache) { ActiveSupport::Cache::MemCacheStore.new }

    it 'does not cleanup' do
      described_class.perform_now
      expect(Rails.cache).not_to have_received :cleanup
    end
  end
end
