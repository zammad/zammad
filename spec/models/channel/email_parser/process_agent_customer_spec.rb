# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser process email from agent-customer', type: :model do
  let(:group)         { Group.lookup(name: 'Users') }
  let(:other_group)   { create(:group) }
  let(:email)         { Channel::EmailParser.new.process({ group_id: group.id, trusted: false }, data) }
  let(:ticket)        { email[0] }
  let(:article)       { email[1] }
  let(:data) do
    <<~MAIL
      From: #{user.firstname} <#{user.email}>
      To: customer@example.com
      Subject: some subject

      Some Text
    MAIL
  end

  context 'when user is agent' do
    context 'when user has access to the selected group' do
      let(:user) { create(:agent, groups: [group]) }

      it 'sets article sender to agent' do
        expect(article.sender.name).to match('Agent')
      end
    end

    context 'when user does not have access to the selected group' do
      let(:user) { create(:agent, groups: [other_group]) }

      it 'sets article sender to customer' do
        expect(article.sender.name).to match('Customer')
      end
    end
  end

  context 'when user is customer' do
    let(:user) { create(:customer) }

    it 'sets article sender to customer' do
      expect(article.sender.name).to match('Customer')
    end
  end

  context 'when user is agent and customer' do
    context 'when user is agent in the selected group' do
      let(:user) { create(:agent_and_customer, groups: [group]) }

      it 'sets article sender to agent' do
        expect(article.sender.name).to match('Agent')
      end
    end

    context 'when user is customer in the selected group' do
      let(:user) { create(:agent_and_customer, groups: [other_group]) }

      it 'sets article sender to customer' do
        expect(article.sender.name).to match('Customer')
      end
    end
  end
end
