# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Output::User, :aggregate_failures do
  describe '.row' do
    it 'gives a reference to the user, with the email where there is one, and the name for a line of facts' do
      user = create(:customer, firstname: 'Anna <b>', lastname: 'Example', email: 'anna@example.com')
      row  = described_class.row(user)

      expect(row.content).to eq(type: 'User', id: user.id, name: 'Anna <b> Example', email: 'anna@example.com')
      expect(row.text).to eq('Anna &lt;b&gt; Example (anna@example.com)')
    end

    it 'leaves out an email the user does not have' do
      user = create(:customer, firstname: 'Ben', lastname: 'Example', email: '')

      expect(described_class.row(user).content).to eq(type: 'User', id: user.id, name: 'Ben Example')
    end
  end
end
