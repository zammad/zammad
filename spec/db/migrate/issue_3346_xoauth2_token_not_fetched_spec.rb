# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3346Xoauth2TokenNotFetched, type: :db_migration do

  shared_examples 'XOAUTH2 channel migration' do |channel_type|

    context 'when valid Channel is present' do

      before do
        channel = create(channel_type)
        channel.options[:inbound][:options][:password] = 'some_password'
        channel.save!
      end

      it "doesn't refresh the token" do
        allow(ExternalCredential).to receive(:refresh_token)
        migrate
        expect(ExternalCredential).not_to have_received(:refresh_token)
      end
    end

    context 'when broken Channel is present' do

      before do
        channel = create(channel_type)
        channel.options[:inbound][:options].delete(:password)
        channel.save!
      end

      it 'refreshes the token' do
        allow(ExternalCredential).to receive(:refresh_token)
        migrate
        expect(ExternalCredential).to have_received(:refresh_token)
      end

      it "doesn't break if refresh fails" do
        allow(ExternalCredential).to receive(:refresh_token).and_raise(RuntimeError)
        expect { migrate }.not_to raise_error
      end
    end
  end

  context 'when Microsoft365 Channel is present' do
    it_behaves_like 'XOAUTH2 channel migration', :microsoft365_channel
  end

  context 'when Google Channel is present' do
    it_behaves_like 'XOAUTH2 channel migration', :google_channel
  end
end
