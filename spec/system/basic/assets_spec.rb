# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The attribute filtering itself is covered by the model specs of User::Assets, Group::Assets,
#   Organization::Assets and Role::Assets.
RSpec.describe 'Assets', type: :system do
  let(:organization) { create(:organization, note: 'hello') }
  let(:customer)     { create(:customer, organization: organization, note: 'hello') }
  let(:agent)        { create(:agent, groups: [Group.find_by(name: 'Users')], note: 'hello') }
  let(:ticket)       { create(:ticket, owner: agent, group: Group.find_by(name: 'Users'), customer: customer) }

  def asset_attribute(model, id, attribute)
    page.evaluate_script("App.#{model}.find(#{id}).#{attribute}")
  end

  def available_group_count
    page.evaluate_script('App.Group.all().length')
  end

  context 'when customer', authenticated_as: :customer do
    before do
      visit "#ticket/zoom/#{ticket.id}"
      find('.ticketZoom')
    end

    it 'receives filtered assets' do
      expect(asset_attribute('User', agent.id, 'firstname')).to eq(agent.firstname)
      expect(asset_attribute('User', agent.id, 'note')).to be_nil
      expect(asset_attribute('Organization', organization.id, 'note')).to be_nil
      expect(asset_attribute('Group', Group.find_by(name: 'Users').id, 'note')).to be_nil
    end

    context 'when groups are restricted', authenticated_as: :authenticate do
      let(:agent_groups) { create_list(:group, 3) }

      def authenticate
        create(:ticket, group: agent_groups.first, customer: customer)
        Setting.set('customer_ticket_create_group_ids', [Group.first.id])
        customer
      end

      it 'receives only the configured groups and the groups of own tickets' do
        expect(available_group_count).to eq(2)
      end
    end
  end

  context 'when agent', authenticated_as: :agent do
    before do
      visit "#ticket/zoom/#{ticket.id}"
      find('.ticketZoom')
    end

    it 'receives unfiltered assets' do
      expect(asset_attribute('User', customer.id, 'note')).to eq('hello')
      expect(asset_attribute('Organization', organization.id, 'note')).to eq('hello')
    end
  end
end
