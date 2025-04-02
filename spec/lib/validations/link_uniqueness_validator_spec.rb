# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Validations::LinkUniquenessValidator do
  let(:instance) { described_class.new }

  shared_examples 'adds an error' do
    it 'adds an error' do
      instance.validate(record)

      expect(record.errors.full_messages).to include('Link already exists')
    end
  end

  shared_examples 'does not add an error' do
    it 'does not add an error' do
      instance.validate(record)

      expect(record.errors).to be_blank
    end
  end

  context 'when creating a new link' do
    let(:record) { build(:link) }

    context 'when an unrelated link exists' do
      before do
        create(:link, from: create(:ticket), to: create(:ticket), link_type: 'other')
      end

      include_examples 'does not add an error'
    end

    context 'when an identical link exists' do
      before { create(:link) }

      include_examples 'adds an error'
    end

    context 'when a partially identical link exists' do
      before { create(:link, link_type: 'other') }

      include_examples 'does not add an error'
    end
  end

  context 'when editing an existing link' do
    let(:record) { create(:link) }

    context 'when an unrelated link exists' do
      before do
        create(:link, from: create(:ticket), to: create(:ticket), link_type: 'other')
      end

      include_examples 'does not add an error'
    end

    context 'when an identical link exists' do
      before do
        create(:link, link_type: 'target')
        record.link_type = Link::Type.create_if_not_exists(name: 'target', active: true)
      end

      include_examples 'adds an error'
    end

    context 'when a partially identical link exists' do
      before do
        create(:link, link_type: 'other')
        record.link_type = Link::Type.create_if_not_exists(name: 'target', active: true)
      end

      include_examples 'does not add an error'
    end
  end
end
