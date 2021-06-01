# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MentionInit, type: :db_migration do

  let(:mocked_table_actions) do
    lambda { |migration|
      # mock DB connection with null object to "null" all connection actions
      allow(migration).to receive(:connection).and_return(double('ActiveRecord::ConnectionAdapters::*').as_null_object) # rubocop:disable RSpec/VerifiedDoubles
    }
  end

  context 'when agent is present' do

    subject(:user) do
      agent = create(:agent)
      agent.preferences['notification_config'] = notification_config
      agent.tap(&:save!)
    end

    context 'when matrix misses type key' do

      let(:notification_config) do
        {
          'matrix' => {
            'create'           => {
              'criteria' => {
                'subscribed' => true
              }
            },
            'update'           => {
              # 'criteria' => {
              #   'subscribed' => true
              # }
            },
            'reminder_reached' => {
              'criteria' => {
                'subscribed' => false
              }
            },
            'escalation'       => {
              'criteria' => {
                'subscribed' => false
              }
            },
          }
        }
      end

      it 'adds type' do # rubocop:disable RSpec/ExampleLength
        expect do
          migrate(&mocked_table_actions)
        end
          .to change {
                user.reload.preferences['notification_config']['matrix']['update']
              }
          .from({})
          .to(
            {
              'criteria' => {
                'subscribed' => true
              }
            }
          )
      end
    end
  end
end
