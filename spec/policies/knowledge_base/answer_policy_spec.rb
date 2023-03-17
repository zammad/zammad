# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'policies/knowledge_base_policy_examples'

describe KnowledgeBase::AnswerPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { create(:knowledge_base_answer) }
  let(:user)   { create(:user) }

  shared_context 'with answer visibility' do |visible:, visible_internally:|
    before do
      allow(record).to receive(:visible?).and_return(visible)
      allow(record).to receive(:visible_internally?).and_return(visible_internally)
    end
  end

  describe '#show?' do
    context 'when visible and visible internally' do
      include_examples 'with answer visibility', visible: true, visible_internally: true
      include_examples 'with KB policy check', editor: true, reader: true, none: true, method: :show?
    end

    context 'when visible internally only' do
      include_examples 'with answer visibility', visible: false, visible_internally: true
      include_examples 'with KB policy check', editor: true, reader: true, none: false, method: :show?
    end

    context 'when not visible' do
      include_examples 'with answer visibility', visible: false, visible_internally: false
      include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :show?
    end
  end

  describe '#show_public?' do
    context 'when visible and visible internally' do
      include_examples 'with answer visibility', visible: true, visible_internally: true
      include_examples 'with KB policy check', editor: true, reader: true, none: true, method: :show_public?
    end

    context 'when visible internally only' do
      include_examples 'with answer visibility', visible: false, visible_internally: true
      include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :show_public?
    end

    context 'when not visible' do
      include_examples 'with answer visibility', visible: false, visible_internally: false
      include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :show_public?
    end
  end

  describe '#update?' do
    include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :update?
  end

  describe '#create?' do
    include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :create?
  end

  describe '#destroy?' do
    include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :destroy?
  end
end
