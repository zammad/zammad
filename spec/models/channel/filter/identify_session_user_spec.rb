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

    context 'when the FROM address is invalid' do
      let(:from_email) { 'foo@bar@example.com' }
      let(:from_name)  { 'Foo Bar' }

      it 'creates a new customer with the address as login and no email' do
        filter(mail_hash)

        expect(User.find(mail_hash[:'x-zammad-session-user-id'])).to have_attributes(
          login:     from_email,
          email:     '',
          firstname: 'Foo',
          lastname:  'Bar',
        )
      end

      context 'when a user with the address as login exists' do
        let!(:user) { create(:customer, login: from_email, email: '') }

        it 'uses the given user' do
          filter(mail_hash)

          expect(mail_hash[:'x-zammad-session-user-id']).to eq(user.id)
        end
      end
    end

    context 'when the mail has no FROM' do
      let(:mail_hash) { Channel::EmailParser.new.parse(<<~RAW.chomp, allow_missing_attribute_exceptions: false) }
        To: #{to_email}
        Subject: Test subject

        Some nice text!
      RAW

      it 'uses the system account', :aggregate_failures do
        expect { filter(mail_hash) }.not_to change(User, :count)

        expect(mail_hash[:'x-zammad-session-user-id']).to eq(1)
      end
    end
  end
end
