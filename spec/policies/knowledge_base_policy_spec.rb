# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'policies/knowledge_base_policy_examples'

describe KnowledgeBasePolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { create(:knowledge_base) }
  let(:user)   { create(:user) }

  describe '#show?' do
    include_examples 'with KB policy check', editor: true, reader: true, none: false, method: :show?
  end

  describe '#show_any?' do
    context 'when the knowledge base is active' do
      include_examples 'with KB policy check', editor: true, reader: true, none: true, method: :show_any?
    end

    context 'when the knowledge base is inactive' do
      let(:record) { create(:knowledge_base, active: false) }

      include_examples 'with KB policy check', editor: true, reader: true, none: false, method: :show_any?
    end
  end

  describe 'update?' do
    include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :update?
  end
end
