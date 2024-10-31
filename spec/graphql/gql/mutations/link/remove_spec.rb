# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
  let(:type)       { ENV.fetch('LINK_TYPE') { %w[child parent normal].sample } }

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

    next if RSpec.configuration.formatters.first
      .class.name.exclude?('DocumentationFormatter')

    puts "with link type: #{type}" # rubocop:disable Rails/Output
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

    context 'when reverse link exists' do
      before do
        create(:link, from: to, to: from, link_type: type)
      end

      it 'removes both links if existing' do
        decremet = type == 'normal' ? -2 : -1
        expect { gql.execute(mutation, variables: variables) }
          .to change(Link, :count).by(decremet)
      end
    end

    context 'when source is not accessible' do
      let(:authenticated) { create(:agent, groups: [to_group]) }

      it 'raises an error' do
        gql.execute(mutation, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when target is not accessible' do
      let(:authenticated) { create(:agent, groups: [from_group]) }

      it 'raises an error' do
        gql.execute(mutation, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
