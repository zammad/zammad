# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/core_workflow/base'

RSpec.describe CoreWorkflow::Custom::TicketTimeAccountingCheck, type: :model do
  include_context 'with core workflow base'

  before do
    Setting.set('time_accounting', true)
  end

  describe 'Time accounting shown for customer #4739' do
    let!(:action_user)    { create(:customer) }
    let(:ticket_customer) { action_user }
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    it 'does not show for customers' do
      expect(result.dig(:flags, :time_accounting)).not_to be(true)
    end
  end

  describe 'Cannot change organisation of ticket #4744' do
    let(:payload) do
      base_payload.merge('params' => { 'customer_id' => '', 'organization_id' => '' }, 'screen' => 'edit')
    end

    before do
      action_user.update(groups: create_list(:group, 3))
    end

    it 'does not show for customers' do
      expect { result }.not_to raise_error(NoMethodError)
    end
  end

  describe 'Stop after match does disable the time accounting detection #5556' do
    let(:payload) do
      base_payload.merge('params' => { 'id' => ticket.id }, 'screen' => 'edit')
    end

    before do
      create(:core_workflow, stop_after_match: true)
    end

    it 'does show if there is a stop after match core workflow configured' do
      expect(result.dig(:flags, :time_accounting)).to be(true)
    end
  end
end
