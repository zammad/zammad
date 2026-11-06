# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Locator::User, :aggregate_failures do
  let(:agent)    { create(:agent) }
  let(:customer) { create(:customer, email: 'anna@example.com') }

  def locator(arguments)
    described_class.new(arguments.stringify_keys)
  end

  describe '#record_id' do
    it 'finds the user by ID, or by email as it is stored, the ID first' do
      expect(locator(user_id: customer.id).record_id).to eq(customer.id)
      expect(locator(email: ' Anna@Example.com ').record_id).to eq(customer.id)
      expect(locator(user_id: agent.id, email: customer.email).record_id).to eq(agent.id)
    end

    it 'finds an email whose domain is written in Punycode' do
      umlaut = create(:customer, email: 'kim@müller.example')

      expect(locator(email: 'kim@xn--mller-kva.example').record_id).to eq(umlaut.id)
    end

    it 'refuses an email several users share, as the system may allow' do
      Setting.set('user_email_multiple_use', true)
      create(:customer, email: customer.email)

      expect { locator(email: customer.email).record_id }.to raise_error(Service::AI::Tool::AmbiguousNameError, described_class::SHARED_EMAIL)
    end

    it 'finds none for an unknown email' do
      expect(locator(email: 'nobody@example.com').record_id).to be_nil
    end
  end

  describe '#named_by?' do
    it 'takes a user among the given IDs, or one the agent named by email or by ID' do
      expect(locator(user_id: customer.id).named_by?(ids: [customer.id], texts: [], user: agent)).to be(true)
      expect(locator(email: customer.email).named_by?(ids: [], texts: ['Call ANNA@example.com, please.'], user: agent)).to be(true)
      expect(locator(user_id: customer.id).named_by?(ids: [], texts: ["The customer with ID #{customer.id}."], user: agent)).to be(true)
    end

    it 'takes a user named in the other form, as the email of a listed user or the ID of a written email' do
      expect(locator(email: customer.email).named_by?(ids: [customer.id], texts: [], user: agent)).to be(true)
      expect(locator(user_id: customer.id).named_by?(ids: [], texts: ["Mail #{customer.email}."], user: agent)).to be(true)
    end

    it 'refuses a user nobody named' do
      expect(locator(user_id: customer.id).named_by?(ids: [agent.id], texts: ['Call 555 1234.'], user: agent)).to be(false)
      expect(locator(email: customer.email).named_by?(ids: [], texts: ['Write to someone@example.com.'], user: agent)).to be(false)
      expect(locator({}).named_by?(ids: [customer.id], texts: [], user: agent)).to be(false)
    end

    it 'refuses a user named in the other form whom the reader may not see' do
      reader = create(:customer)

      expect(locator(user_id: customer.id).named_by?(ids: [], texts: ["Mail #{customer.email}."], user: reader)).to be(false)
    end
  end
end
