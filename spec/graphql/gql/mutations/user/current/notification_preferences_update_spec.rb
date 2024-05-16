# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::NotificationPreferencesUpdate, :aggregate_failures, type: :graphql do
  let(:user) { create(:agent) }

  let(:mutation) do
    <<~GQL
      mutation userCurrentNotificationPreferencesUpdate($groupIds: [ID!], $matrix: UserNotificationMatrixInput!, $sound: UserNotificationSoundInput!) {
        userCurrentNotificationPreferencesUpdate(groupIds: $groupIds, matrix: $matrix, sound: $sound) {
          user {
            personalSettings {
              notificationConfig {
                groupIds
                matrix {
                  create {
                    channel {
                      email
                      online
                    }
                    criteria {
                      ownedByMe
                      ownedByNobody
                      subscribed
                      no
                    }
                  }
                  update {
                    channel {
                      email
                      online
                    }
                    criteria {
                      ownedByMe
                      ownedByNobody
                      subscribed
                      no
                    }
                  }
                  reminderReached {
                    channel {
                      email
                      online
                    }
                    criteria {
                      ownedByMe
                      ownedByNobody
                      subscribed
                      no
                    }
                  }
                  escalation {
                    channel {
                      email
                      online
                    }
                    criteria {
                      ownedByMe
                      ownedByNobody
                      subscribed
                      no
                    }
                  }
                }
              }
              notificationSound {
                enabled
                file
              }
            }
          }
        }
      }
    GQL
  end

  let(:matrix_row) do
    {
      'channel'  => { 'email' =>  false, 'online' => true },
      'criteria' => { 'ownedByMe' => true, 'ownedByNobody' => false, 'subscribed' => true, 'no' => false },
    }
  end

  let(:matrix) do
    {
      'create'          => matrix_row.dup,
      'update'          => matrix_row.dup,
      'reminderReached' => matrix_row.dup,
      'escalation'      => matrix_row.dup,
    }
  end

  let(:group_ids) { nil }
  let(:sound) { { 'enabled' => true, 'file' => 'Bell' } }

  let(:variables) { { groupIds: group_ids, matrix:, sound: } }

  def execute_graphql_query
    gql.execute(mutation, variables: variables)
  end

  context 'when user is not authenticated' do
    it 'returns an error' do
      expect(execute_graphql_query.error_message).to eq('Authentication required')
    end
  end

  context 'when user is authenticated', authenticated_as: :user do
    context 'without sufficient permissions', authenticated_as: :user do
      let(:user) do
        create(:agent).tap do |user|
          user.roles.each { |role| role.permission_revoke('user_preferences') }
        end
      end

      it 'returns an error' do
        expect(execute_graphql_query.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'with sufficient permissions' do

      context 'without group_ids' do
        let(:expected_preferences) do
          {
            'notificationConfig' => {
              'matrix'   => matrix,
              'groupIds' => nil,
            },
            'notificationSound'  => sound
          }
        end

        it 'updates user profile notification settings' do
          execute_graphql_query
          expect(gql.result.data['user']['personalSettings']).to include(expected_preferences)
        end
      end

      context 'with empty groupIds' do
        let(:group_ids) { [] }
        let(:expected_preferences) do
          {
            'notificationConfig' => {
              'matrix'   => matrix,
              'groupIds' => nil,
            },
            'notificationSound'  => sound
          }
        end

        it 'updates user profile notification settings' do
          execute_graphql_query
          expect(gql.result.data['user']['personalSettings']).to include(expected_preferences)
        end
      end

      context 'with group_ids' do
        let(:group_ids) { groups.map { |group| gql.id(group) } }
        let(:groups) do
          create_list(:group, 2).tap do |groups|
            user.groups << groups
            user.save!
          end
        end

        let(:expected_preferences) do
          {
            'notificationConfig' => {
              'matrix'   => matrix,
              'groupIds' => groups.map(&:id),
            },
            'notificationSound'  => sound
          }
        end

        it 'updates user profile notification settings' do
          execute_graphql_query
          expect(gql.result.data['user']['personalSettings']).to include(expected_preferences)
        end
      end
    end
  end
end
