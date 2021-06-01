# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

describe Controllers::KnowledgeBase::CategoriesControllerPolicy do
  subject { described_class.new(user, record) }

  include_context 'basic Knowledge Base'

  let(:record_class) { KnowledgeBase::CategoriesController }

  let(:record) do
    rec             = record_class.new
    rec.action_name = action_name
    rec.params      = params

    rec
  end

  describe '#show?' do
    let(:action_name) { :show }
    let(:params)      { { id: internal_answer.category.id } }

    context 'with knowledge_base.reader permissions' do
      let(:user) { create(:agent) }

      it { is_expected.to permit_action(action_name) }
    end
  end
end
