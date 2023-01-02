# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::ZammadSchema, type: :graphql do

  context 'when making queries that are too complex', authenticated_as: :agent do
    let(:agent) { create(:agent, department: 'TestDepartment') }
    let(:query) do
      <<~QUERY
        query currentUser {
          currentUser {
            organization {
              members {
                edges {
                  node {
                    firstname
                    organization {
                      members {
                        edges {
                          node {
                            firstname
                            organization {
                              name
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      QUERY
    end

    before do
      gql.execute(query)
    end

    it 'has data' do
      expect(gql.result.error_message).to eq('Query has depth of 11, which exceeds max depth of 10')
    end
  end
end
