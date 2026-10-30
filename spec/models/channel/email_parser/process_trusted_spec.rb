# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser process trusted', aggregate_failures: true, type: :model do

  context 'when the channel is trusted' do
    let(:agent1) do
      User.create!(
        login:         'agent1',
        firstname:     'Firstname',
        lastname:      'agent1',
        email:         'agent1@example.com',
        active:        true,
        roles:         Role.where(name: 'Agent'),
        groups:        Group.all,
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

    let(:customer1) do
      User.create!(
        login:         'customer1',
        firstname:     'Firstname',
        lastname:      'customer1',
        email:         'customer1@example.com',
        active:        true,
        roles:         Role.where(name: 'Customer'),
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

    let(:files) do
      [
        {
          data:    'From: me@example.com
To: customer@example.com
Subject: some subject
X-Zammad-Ignore: true

Some Text',
          channel: {
            trusted: true,
          },
          success: false,
        },
        {
          data:    'From: me@example.com
To: customer@example.com
Subject: some subject
X-Zammad-Ticket-Followup-State: closed
X-Zammad-Ticket-priority: 3 high
X-Zammad-Ticket-owner: agent1@example.com
X-Zammad-Article-sender: System
x-Zammad-Article-type: phone
x-Zammad-Article-Internal: true

Some Text',
          channel: {
            trusted: true,
          },
          success: true,
          result:  {
            0 => {
              state:    'new',
              priority: '3 high',
              title:    'some subject',
              owner:    agent1,
            },
            1 => {
              sender:   'System',
              type:     'phone',
              internal: true,
            },
          },
        },
        {
          data:    'From: me@example.com
To: customer@example.com
Subject: some subject
X-Zammad-Ticket-Followup-State: closed
X-Zammad-Ticket-priority_id: 777777
X-Zammad-Ticket-owner: not_existing@example.com
X-Zammad-Article-sender_id: 999999
x-Zammad-Article-type: phone
x-Zammad-Article-Internal: true

Some Text',
          channel: {
            trusted: true,
          },
          success: true,
          result:  {
            0 => {
              state:    'new',
              priority: '2 normal',
              title:    'some subject',
              owner:    User.find(1),
            },
            1 => {
              sender:   'Customer',
              type:     'phone',
              internal: true,
            },
          },
        },
        {
          data:    'From: me@example.com
To: customer@example.com
Subject: some subject / with customer as agent - customer can not be owner
X-Zammad-Ticket-owner: customer1@example.com

Some Text',
          channel: {
            trusted: true,
          },
          success: true,
          result:  {
            0 => {
              state:    'new',
              priority: '2 normal',
              title:    'some subject / with customer as agent - customer can not be owner',
              owner:    User.find(1),
            },
            1 => {
              sender:   'Customer',
              type:     'email',
              internal: false,
            },
          },
        },
        {
          data:    'From: me@example.com
To: customer@example.com
Subject: some subject / with agent login
X-Zammad-Ticket-owner: agent1

Some Text',
          channel: {
            trusted: true,
          },
          success: true,
          result:  {
            0 => {
              state:    'new',
              priority: '2 normal',
              title:    'some subject / with agent login',
              owner:    agent1,
            },
            1 => {
              sender:   'Customer',
              type:     'email',
              internal: false,
            },
          },
        },
        {
          data:    'From: me@example.com
To: customer@example.com
Subject: some subject / with agent login in another case
X-Zammad-Ticket-owner: AGENT1

Some Text',
          channel: {
            trusted: true,
          },
          success: true,
          result:  {
            0 => {
              state:    'new',
              priority: '2 normal',
              title:    'some subject / with agent login in another case',
              owner:    User.find(1),
            },
            1 => {
              sender:   'Customer',
              type:     'email',
              internal: false,
            },
          },
        },
        {
          data:    'From: me@example.com
To: customer@example.com
Subject: some subject / with agent email
X-Zammad-Ticket-owner: agent1@example.com

Some Text',
          channel: {
            trusted: true,
          },
          success: true,
          result:  {
            0 => {
              state:    'new',
              priority: '2 normal',
              title:    'some subject / with agent email',
              owner:    agent1,
            },
            1 => {
              sender:   'Customer',
              type:     'email',
              internal: false,
            },
          },
        },
      ]
    end

    before do
      customer1
    end

    it 'processes the X-Zammad headers as expected' do
      assert_process(files)
    end
  end

  context 'when the channel is not trusted' do
    let(:files) do
      [
        {
          data:    'From: me@example.com
To: customer@example.com
Subject: some subject
X-Zammad-Ticket-Followup-State: closed
X-Zammad-Ticket-Priority: 3 high
X-Zammad-Article-Sender: System
x-Zammad-Article-Type: phone
x-Zammad-Article-Internal: true

Some Text',
          channel: {
            trusted: false,
          },
          success: true,
          result:  {
            0 => {
              state:    'new',
              priority: '2 normal',
              title:    'some subject',
            },
            1 => {
              sender:   'Customer',
              type:     'email',
              internal: false,
            },
          },
        },
      ]
    end

    it 'ignores the X-Zammad headers' do
      assert_process(files)
    end
  end

  context 'when the channel is not trusted and the mail is secured with S/MIME' do
    before do
      Setting.set('smime_integration', true)
    end

    let(:system_email_address) { 'smime1@example.com' }
    let(:sender_email_address) { 'smime2@example.com' }

    let(:agent)           { create(:agent) }
    let(:other_customer)  { create(:customer) }
    let(:existing_ticket) { create(:ticket, title: 'existing ticket') }

    let(:payload) do
      <<~PAYLOAD.gsub(%r{\n}, "\r\n")
        Content-Type: text/plain

        Secured body
      PAYLOAD
    end

    def secured_mail(secured_body)
      headers = <<~HEADERS.gsub(%r{\n}, "\r\n")
        From: #{sender_email_address}
        To: #{system_email_address}
        Subject: secured mail
        X-Zammad-Ticket-Id: #{existing_ticket.id}
        X-Zammad-Session-User-Id: #{agent.id}
        X-Zammad-Ticket-Followup-Customer: #{other_customer.email}
        X-Zammad-Article-Internal: true
      HEADERS

      "#{headers}#{secured_body}"
    end

    def opaque_signed_body
      key  = OpenSSL::PKey::RSA.new(2048)
      cert = OpenSSL::X509::Certificate.new
      cert.version    = 2
      cert.serial     = 1
      cert.subject    = OpenSSL::X509::Name.parse("/CN=example.com/emailAddress=#{sender_email_address}")
      cert.issuer     = cert.subject
      cert.public_key = key.public_key
      cert.not_before = Time.zone.now
      cert.not_after  = 1.hour.from_now
      cert.sign(key, OpenSSL::Digest.new('SHA256'))

      # Flag 0 (no DETACHED) embeds the content in the PKCS7 structure (opaque signature).
      OpenSSL::PKCS7.write_smime(OpenSSL::PKCS7.sign(cert, key, payload, [], 0))
    end

    def enveloped_body
      recipient_certificate = OpenSSL::X509::Certificate.new(Rails.root.join("spec/fixtures/files/smime/#{system_email_address}.crt").read)

      OpenSSL::PKCS7.write_smime(OpenSSL::PKCS7.encrypt([recipient_certificate], payload, OpenSSL::Cipher.new('AES-128-CBC')))
    end

    shared_examples 'keeping the original mail attributes' do
      it 'processes the secured content and keeps the original mail attributes' do
        customer_id_before = existing_ticket.customer_id

        ticket, article, = Channel::EmailParser.new.process({ trusted: false }, mail)

        # The secured content is processed, so the re-parse really happened.
        expect(article.body).to include('Secured body')

        expect(ticket).to be_present
        expect(ticket.id).not_to eq(existing_ticket.id)
        expect(article.internal).to be false
        expect(article.created_by_id).not_to eq(agent.id)

        expect(existing_ticket.reload.customer_id).to eq(customer_id_before)
        expect(existing_ticket.articles).to be_empty
      end
    end

    context 'with an opaque signature from an unknown signer' do
      let(:mail) { secured_mail(opaque_signed_body) }

      include_examples 'keeping the original mail attributes'
    end

    context 'with an enveloped message' do
      before do
        create(:smime_certificate, :with_private, fixture: system_email_address)
      end

      let(:mail) { secured_mail(enveloped_body) }

      include_examples 'keeping the original mail attributes'
    end
  end

  def assert_process(files)
    files.each do |file|
      result = Channel::EmailParser.new.process(file[:channel] || {}, file[:data])

      if file[:success]
        expect(result).to be_a(Array)
        expect(result[1]).to be_truthy, 'ticket not created'

        assert_process_result(file, result)
      else
        expect(result[1]).to be_falsey, 'ticket should not be created but is created'
      end
    end
  end

  def assert_process_result(file, result)
    return if !file[:result]

    [0, 1, 2].each do |level|
      file[:result][level]&.each do |key, value|
        if result[level].send(key).respond_to?(:name)
          expect(result[level].send(key).name).to eq(value.to_s)
        else
          expect(result[level].send(key)).to eq(value), "result check #{level}, #{key}"
        end
      end
    end
  end
end
