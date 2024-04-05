# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Validations::ChannelEmailAccountUniquenessValidator do
  subject(:validator) { described_class.new }

  before { Channel.destroy_all }

  it 'a new record in empty database passes' do
    channel = build(:email_channel, :smtp, :imap)

    validator.validate(channel)

    expect(channel.errors).to be_blank
  end

  context 'with an existing record' do
    let(:mail_server_user) { 'user@example.com' }

    before { create(:email_channel, :smtp, :imap, mail_server_user:) }

    it 'identical record fails' do
      channel = build(:email_channel, :smtp, :imap, mail_server_user:)

      validator.validate(channel)

      expect(channel.errors).to be_present
    end

    it 'record with a different inbound server passes' do
      channel = build(:email_channel, :smtp, :pop3, mail_server_user:)

      validator.validate(channel)

      expect(channel.errors).to be_blank
    end

    context 'with another existing record' do
      let(:another_channel) { create(:email_channel, :smtp, :imap, mail_server_user: 'other@example.com') }

      it 'editing a persisted record to be identical fails' do
        another_channel.options[:inbound][:options][:user] = mail_server_user

        validator.validate(another_channel)

        expect(another_channel.errors).to be_present
      end

      it 'editing a persisted record passes' do
        another_channel.options[:inbound][:options][:folder] = 'foobar'

        validator.validate(another_channel)

        expect(another_channel.errors).to be_blank
      end
    end

    # https://github.com/zammad/zammad/issues/5111
    context 'with multiple identical channels' do
      let(:duplicate_channel) { create(:google_channel, gmail_user: 'email@example.com') }
      let(:editable_channel) do
        build(:google_channel, gmail_user: 'email@example.com')
          .tap { _1.save!(validate: false) }
      end

      let(:new_token) { 'new_xoauth2_token' }

      before do
        duplicate_channel

        allow(ExternalCredential)
          .to receive(:refresh_token).and_return(access_token: new_token)
      end

      it 'allows to edit XOauth2 token if identical channel exists' do
        editable_channel.refresh_xoauth2!(force: true)

        expect(editable_channel.options).to include(
          inbound:  include(options: include(password: new_token)),
          outbound: include(options: include(password: new_token)),
        )
      end
    end
  end
end
