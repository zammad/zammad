# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Output::Organization, :aggregate_failures do
  describe '.row' do
    it 'gives a reference to the organization, and its name for a line of facts' do
      organization = create(:organization, name: 'Example <Corp>')
      row          = described_class.row(organization)

      expect(row.content).to eq(type: 'Organization', id: organization.id, name: 'Example <Corp>')
      expect(row.text).to eq('Example &lt;Corp&gt;')
    end
  end
end
