# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Link::Remove, :aggregate_failures, type: :graphql do
  let(:mutation) do
    <<~MUTATION
      mutation linkRemove($input: LinkInput!) {
        linkRemove(input: $input) {
          success
          errors {
            message
            field
          }
        }
      }
    MUTATION
  end

  let(:from_group) { create(:group) }
  let(:from)       { create(:ticket, group: from_group) }
  let(:to_group)   { create(:group) }
  let(:to)         { create(:ticket, group: to_group) }
  let(:type)       { 'normal' }

  let(:input) do
    {
      sourceId: gql.id(from),
      targetId: gql.id(to),
      type:     type
    }
  end

  let(:variables) { { input: input } }

  before do
    create(:link, from: from, to: to, link_type: type)
  end

  context 'with unauthenticated session' do
    it 'raises an error' do
      gql.execute(mutation, variables: variables)
      expect(gql.result.error_type).to eq(Exceptions::NotAuthorized)
    end
  end

  context 'with authenticated session', authenticated_as: :authenticated do
    let(:authenticated) { create(:agent, groups: [from_group, to_group]) }

    it 'remove link' do
      expect { gql.execute(mutation, variables: variables) }
        .to change(Link, :count).by(-1)
    end

    shared_examples 'removing link' do
      context 'when reverse link exists' do
        let(:decremet) { type == 'normal' ? -2 : -1 }

        before do
          create(:link, from: to, to: from, link_type: type)
        end

        context 'when source is accessible' do
          it 'removes both links if existing' do
            expect { gql.execute(mutation, variables: variables) }
              .to change(Link, :count).by(decremet)
          end
        end

        context 'when source is not accessible' do
          let(:authenticated) { create(:agent, groups: [to_group]) }

          it 'removes both links if existing' do
            expect { gql.execute(mutation, variables: variables) }
              .to change(Link, :count).by(decremet)
          end
        end
      end
    end

    %w[child parent normal].each do |link_type|
      context "with link type #{link_type}" do
        let(:type) { link_type }

        it_behaves_like 'removing link'
      end
    end

    context 'when target is not accessible' do
      let(:authenticated) { create(:agent, groups: [from_group]) }

      it 'raises an error' do
        gql.execute(mutation, variables: variables)
        expect(gql.result.error_type).to eq(Pundit::NotAuthorizedError)
      end
    end
  end
end
