# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CanPaginate::Pagination do
  describe '#limit' do
    it 'returns as set in params' do
      instance = described_class.new({ per_page: 123 })
      expect(instance.limit).to be 123
    end

    it 'ensures that per_page is an integer' do
      instance = described_class.new({ per_page: '123' })
      expect(instance.limit).to be 123
    end

    it 'when missing, returns as set in limit attribute' do
      instance = described_class.new({ limit: 123 })
      expect(instance.limit).to be 123
    end

    it 'falls back to default' do
      instance = described_class.new({})
      expect(instance.limit).to be 100
    end

    it 'falls back to custom default' do
      instance = described_class.new({}, default: 222)
      expect(instance.limit).to be 222
    end

    it 'per_page attribute preferred over limit' do
      instance = described_class.new({ per_page: 123, limit: 321 })
      expect(instance.limit).to be 123
    end

    it 'capped by limit' do
      instance = described_class.new({ per_page: 9999 })
      expect(instance.limit).to be 1000
    end

    it 'capped by custom default' do
      instance = described_class.new({ per_page: 9999 }, max: 10)
      expect(instance.limit).to be 10
    end
  end

  describe '#page' do
    it 'returns page number' do
      instance = described_class.new({ page: 123 })
      expect(instance.page).to be 123
    end

    it 'defaults to 1 when missing' do
      instance = described_class.new({})
      expect(instance.page).to be 1
    end

    it 'ensures that page is an integer' do
      instance = described_class.new({ page: '123' })
      expect(instance.page).to be 123
    end
  end

  describe '#offset' do
    it 'returns 0 when no page given' do
      instance = described_class.new({})
      expect(instance.offset).to be 0
    end

    it 'returns offset for page' do
      instance = described_class.new({ page: 3 })
      expect(instance.offset).to be 200
    end

    it 'returns offset based on custom per_page value' do
      instance = described_class.new({ page: 3, per_page: 15 })
      expect(instance.offset).to be 30
    end
  end
end
