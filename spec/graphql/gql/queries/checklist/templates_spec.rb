# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Checklist::Templates, current_user_id: 1, type: :graphql do
  let(:agent)              { create(:agent) }
  let(:checklist_template) { create(:checklist_template) }
  let(:only_active)        { false }

  let(:query) do
    <<~QUERY
      query checklistTemplates($onlyActive: Boolean = false) {
        checklistTemplates(onlyActive: $onlyActive) {
          id
          name
          active
        }
      }
    QUERY
  end

  let(:variables) { { onlyActive: only_active } }

  let(:response) do
    [
      {
        'id'     => gql.id(checklist_template),
        'name'   => checklist_template.name,
        'active' => checklist_template.active,
      },
    ]
  end

  before do
    setup if defined?(setup)
    checklist_template
    gql.execute(query, variables: variables)
  end

  shared_examples 'returning template data' do
    it 'returns template data' do
      expect(gql.result.data).to eq(response)
    end
  end

  shared_examples 'raising an error' do |error_type|
    it 'raises an error' do
      expect(gql.result.error_type).to eq(error_type)
    end
  end

  context 'with authenticated session', authenticated_as: :agent do
    it_behaves_like 'returning template data'

    context 'with disabled checklist feature' do
      let(:setup) do
        Setting.set('checklist', false)
      end

      it_behaves_like 'raising an error', Exceptions::Forbidden
    end

    context 'without agent permissions', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it_behaves_like 'raising an error', Exceptions::Forbidden
    end

    context 'when template does not exist' do
      let(:checklist_template) { nil }
      let(:response)           { [] }

      it_behaves_like 'returning template data'
    end

    context 'with inactive template' do
      let(:checklist_template) { create(:checklist_template, active: false) }

      it_behaves_like 'returning template data'

      context 'with active only filter' do
        let(:only_active) { true }
        let(:response)    { [] }

        it_behaves_like 'returning template data'
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
