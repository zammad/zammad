# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
                nodes {
                  firstname
                  organization {
                    members {
                      nodes {
                        firstname
                        organization {
                          members {
                            nodes {
                              firstname
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
      graphql_execute(query)
    end

    it 'has data' do
      expect(graphql_response['errors']).to eq([{ 'message'=>'Query has depth of 11, which exceeds max depth of 10' }])
    end
  end
end
