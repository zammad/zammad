# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::IdentifySessionUser, type: :channel_filter do
  let(:from_email)      { Faker::Internet.unique.email }
  let(:from_name)       { Faker::Name.unique.name }
  let(:to_email)        { Faker::Internet.unique.email }
  let(:session_user_id) { nil }

  let(:mail_hash) { Channel::EmailParser.new.parse(<<~RAW.chomp) }
    From: #{from_name} <#{from_email}>
    To: #{to_email}
    Subject: Test subject
    #{"x-zammad-session-user-id: #{session_user_id}" if session_user_id}

    Some nice text!
  RAW

  context 'when x-zammad-session-user-id is present' do
    context 'when such user exists' do
      let(:user)            { create(:user) }
      let(:session_user_id) { user.id }

      it 'uses the given user' do
        filter(mail_hash)

        expect(mail_hash[:'x-zammad-session-user-id']).to eq(user.id)
      end
    end

    context 'when such user does not exist' do
      let(:user)            { create(:user) }
      let(:session_user_id) { 123_456 }

      it 'creates a new customer based on from details' do
        filter(mail_hash)

        user_id = mail_hash[:'x-zammad-session-user-id']
        user    = User.find(user_id)
        name    = User.name_guess(from_name, from_email)

        expect(user).to have_attributes(
          email:     from_email,
          firstname: name.first,
          lastname:  name.last,
          login:     from_email,
        )
      end
    end
  end

  context 'when x-zammad-session-user-id is not present' do
    context 'when a user with FROM email exists' do
      let(:user) { create(:user, email: from_email) }

      it 'uses the given user' do
        user

        filter(mail_hash)

        expect(mail_hash[:'x-zammad-session-user-id']).to eq(user.id)
      end
    end

    context 'when a user with FROM email does not exist' do
      it 'creates a new customer' do
        filter(mail_hash)

        user_id = mail_hash[:'x-zammad-session-user-id']
        user    = User.find(user_id)
        name    = User.name_guess(from_name, from_email)

        expect(user).to have_attributes(
          email:     from_email,
          firstname: name.first,
          lastname:  name.last,
          login:     from_email,
        )
      end
    end
  end
end
