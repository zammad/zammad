# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue2460FixCorruptedTwitterIds, type: :db_migration do
  before { allow(Twitter::REST::Client).to receive(:new).and_return(client) }

  let(:client) { double('Twitter::REST::Client', user: twitter_api_user) }
  let(:twitter_api_user) { double('Twitter::User', id: twitter_api_user_id) }
  let(:twitter_api_user_id) { 1234567890 } # rubocop:disable Style/NumericLiterals

  context 'with existing, corrupted Twitter channel' do
    let!(:twitter_channel) { create(:twitter_channel) }

    it 'updates the channel’s stored user ID (as string)' do
      expect { migrate }
        .to change { twitter_channel.reload.options[:user][:id] }
        .to(twitter_api_user_id.to_s)
    end

    context 'with invalid credentials stored' do

      before { allow(Twitter::REST::Client).to receive(:new).and_raise(Twitter::Error::Unauthorized.new('Could not authenticate you.')) }

      it 'skips the Channel' do
        expect { migrate }
          .not_to change { twitter_channel.reload.options[:user][:id] }
      end
    end
  end
end
