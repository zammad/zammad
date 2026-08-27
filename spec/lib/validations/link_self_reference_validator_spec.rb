# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Validations::LinkSelfReferenceValidator do
  let(:instance) { described_class.new }
  let(:ticket)   { create(:ticket) }

  shared_examples 'adds an error' do
    it 'adds an error' do
      instance.validate(record)

      expect(record.errors.full_messages).to include('An object cannot be linked to itself.')
    end
  end

  shared_examples 'does not add an error' do
    it 'does not add an error' do
      instance.validate(record)

      expect(record.errors).to be_blank
    end
  end

  context 'when source and target are different objects' do
    let(:record) { build(:link, from: ticket, to: create(:ticket)) }

    include_examples 'does not add an error'
  end

  context 'when source and target are the same object' do
    let(:record) { build(:link, from: ticket, to: ticket) }

    include_examples 'adds an error'
  end

  context 'when source and target have the same ID but a different object type' do
    let(:record) do
      build(:link,
            from:               ticket,
            to:                 ticket,
            link_object_target: 'KnowledgeBase::Answer::Translation')
    end

    include_examples 'does not add an error'
  end
end
