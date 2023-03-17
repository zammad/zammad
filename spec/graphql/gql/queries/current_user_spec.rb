# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::CurrentUser, type: :graphql do

  context 'when fetching user information' do
    let(:organization)   { create(:organization) }
    let(:secondary_orgs) { create_list(:organization, 2) }
    let(:agent)          { create(:agent, department: 'TestDepartment', organization: organization, organizations: secondary_orgs) }
    let(:query) do
      <<~QUERY
        query currentUser {
          currentUser {
            id
            firstname
            lastname
            fullname
            objectAttributeValues {
              attribute {
                name
              }
              value
              renderedLink
            }
            organization {
              name
            }
            secondaryOrganizations {
              edges {
                node {
                  name
                }
              }
            }
            permissions {
              names
            }
            createdBy {
              firstname
            }
            updatedBy {
              firstname
            }
            policy {
              update
              destroy
            }
          }
        }
      QUERY
    end

    before do
      gql.execute(query)
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'has data' do
        expect(gql.result.data).to include('fullname' => agent.fullname, 'policy' => { 'update' => false, 'destroy' => false })
      end

      context 'when admin' do
        let(:agent) { create(:admin) }

        it 'has policy field data' do
          expect(gql.result.data).to include('policy' => { 'update' => true, 'destroy' => true })
        end
      end

      it 'has objectAttributeValue data for User' do
        oas = gql.result.data['objectAttributeValues']
        expect(oas.find { |oa| oa['attribute']['name'].eql?('department') }).to include('value' => 'TestDepartment', 'renderedLink' => nil)
      end

      context 'with custom object attribute with linktemplate', db_strategy: :reset do
        let(:object_attribute) do
          screens = { create: { 'admin.organization': { shown: true, required: false } } }
          create(:object_manager_attribute_text, name: 'UserLink', object_name: 'User', screens: screens).tap do |oa|
            oa.data_option['linktemplate'] = 'http://test?#{user.fullname}' # rubocop:disable Lint/InterpolationCheck
            oa.save!
            ObjectManager::Attribute.migration_execute
          end
        end
        let(:organization) do
          object_attribute
          create(:organization)
        end

        it 'has rendered objectAttributeValue data for User' do
          oas = gql.result.data['objectAttributeValues']
          expect(oas.find { |oa| oa['attribute']['name'].eql?('UserLink') }).to include('value' => '', 'renderedLink' => "http://test?#{agent.fullname}")
        end
      end

      it 'has data for primary and secondary organizations', :aggregate_failures do
        expect(gql.result.data['organization']).to include('name' => organization.name)
        expect(gql.result.nodes('secondaryOrganizations')).to eq(secondary_orgs.map { |o| { 'name' => o.name } })
      end

      it 'has permission data' do
        expect(gql.result.data['permissions']['names']).to eq(agent.permissions_with_child_names)
      end

      it 'has updatedBy data' do
        expect(gql.result.data['updatedBy']['firstname']).to eq(User.first.firstname)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'

  end
end
