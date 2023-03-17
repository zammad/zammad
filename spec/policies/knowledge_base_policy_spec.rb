# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'policies/knowledge_base_policy_examples'

describe KnowledgeBasePolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { create(:knowledge_base) }
  let(:user)   { create(:user) }

  describe '#show?' do
    include_examples 'with KB policy check', editor: true, reader: true, none: false, method: :show?
  end

  describe 'update?' do
    include_examples 'with KB policy check', editor: true, reader: false, none: false, method: :update?
  end
end
