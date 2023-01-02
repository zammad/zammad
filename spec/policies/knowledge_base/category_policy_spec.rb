# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'policies/knowledge_base_policy_examples'

describe KnowledgeBase::CategoryPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { create(:knowledge_base_category) }
  let(:user)   { create(:user) }

  describe '#show?' do
    include_examples 'with KB policy check', editor: true, reader: true, none: false, method: :show?
  end

  describe '#show_public?' do
    context 'when category has public content' do
      before { allow(record).to receive(:public_content?).and_return(true) }

      include_examples 'with KB policy check', editor: true, reader: true, none: true, method: :show_public?
    end

    context 'when category has no public content' do
      before { allow(record).to receive(:public_content?).and_return(false) }

      include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :show_public?
    end
  end

  describe '#permissions?' do
    include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :permissions?
  end

  describe '#update?' do
    include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :update?
  end

  describe '#create?' do
    include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :create?, access_method: :parent_access
  end

  describe '#destroy?' do
    include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :destroy?, access_method: :parent_access
  end
end
