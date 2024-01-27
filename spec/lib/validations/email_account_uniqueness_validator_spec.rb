# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Validations::EmailAccountUniquenessValidator do
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
  end
end
