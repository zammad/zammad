# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Context::CurrentUserAware, type: :graphql do
  subject(:context) { Gql::ZammadSchema.execute('{ __typename }', context: values).context }

  let(:user)   { create(:agent) }
  let(:values) { { current_user: user } }

  context 'without a channel, as over HTTP' do
    it 'serves the user' do
      expect(context.current_user?).to eq(user)
    end
  end

  context 'with a channel whose connection is still authorized' do
    let(:channel) { build_mock_channel.tap { |c| c.connection = instance_double(ApplicationCable::Connection, still_authorized?: true) } }
    let(:values)  { { current_user: user, channel: channel } }

    it 'serves the user' do
      expect(context.current_user?).to eq(user)
    end
  end

  # The user stays attached to the connection, so this is where a connection that a maintenance
  #   mode no longer authorizes becomes a logged out client.
  context 'with a channel whose connection is no longer authorized' do
    let(:channel) { build_mock_channel.tap { |c| c.connection = instance_double(ApplicationCable::Connection, still_authorized?: false) } }
    let(:values)  { { current_user: user, channel: channel } }

    it 'serves no user' do
      expect(context.current_user?).to be_nil
    end

    it 'requires authentication where the user is mandatory' do
      expect { context.current_user }.to raise_error(Exceptions::NotAuthorized)
    end
  end

  context 'with a channel without a connection, as in channel specs' do
    let(:values) { { current_user: user, channel: build_mock_channel } }

    it 'serves the user' do
      expect(context.current_user?).to eq(user)
    end
  end
end
