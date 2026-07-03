# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser process with inactive group', aggregate_failures: true, type: :model do

  context 'when the channel group is inactive' do
    let(:group3) do
      Group.create_if_not_exists(
        name:          'Test Group Inactive',
        active:        false,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end

    let(:files) do
      [
        {
          data:    'From: me@example.com
To: customer@example.com
Subject: some subject

Some Text',
          channel: {
            group_id: group3.id,
          },
          success: true,
          result:  {
            0 => {
              state:    'new',
              group:    'Users',
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

    it 'creates the ticket in the default group' do
      assert_process(files)
    end
  end

  context 'when all groups are inactive' do
    let(:files) do
      [
        {
          data:    'From: me@example.com
To: customer@example.com
Subject: some subject

Some Text',
          channel: {},
          success: true,
          result:  {
            0 => {
              state:    'new',
              group:    'Users',
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

    before do
      Group.find_each do |group|
        group.update!(active: false)
      end
    end

    it 'creates the ticket in the default group' do
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
