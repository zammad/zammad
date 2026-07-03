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

  def assert_process(files)
    files.each do |file|
      result = Channel::EmailParser.new.process(file[:channel] || {}, file[:data], false)

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
