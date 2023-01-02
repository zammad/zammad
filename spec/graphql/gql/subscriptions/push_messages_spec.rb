# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::PushMessages, type: :graphql do

  let(:subscription) do
    <<~QUERY
      subscription pushMessages {
        pushMessages {
          title
          text
        }
      }
    QUERY
  end
  let(:mock_channel) { build_mock_channel }
  let(:expected_msg) do
    {
      result: {
        'data' => {
          'pushMessages' => {
            'title' => 'Attention',
            'text'  => 'Maintenance test message.',
          }
        }
      },
      more:   true,
    }
  end

  def trigger_push_message(title, text)
    described_class.trigger({ title: title, text: text })
  end

  before do
    gql.execute(subscription, context: { channel: mock_channel })
  end

  it 'broadcasts push message to all users' do
    trigger_push_message('Attention', 'Maintenance test message.')
    expect(mock_channel.mock_broadcasted_messages).to eq([expected_msg])
  end
end
