# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Ticket > Information > Accounted Time', app: :mobile, authenticated_as: :authenticate, type: :system do
  let(:group)           { create(:group) }
  let(:ticket)          { create(:ticket, group: group) }
  let(:article)         { create(:ticket_article, ticket: ticket) }
  let(:time_unit)       { Faker::Number.unique.decimal(l_digits: 1, r_digits: 1) }
  let(:time_accounting) { create(:'ticket/time_accounting', ticket: ticket, ticket_article: article, time_unit: time_unit) }

  let(:accounted_time_element) do
    find('section', text: 'Accounted Time')
  end

  def authenticate
    time_accounting

    user
  end

  before do
    Setting.set('time_accounting', true)

    visit "/tickets/#{ticket.id}/information"
  end

  shared_examples 'showing accounted time' do |time_accounting_unit = '', display_unit = nil|
    before do
      Setting.set('time_accounting_unit', time_accounting_unit) if time_accounting_unit.present?
      Setting.set('time_accounting_unit_custom', display_unit) if time_accounting_unit == 'custom'
    end

    it 'shows accounted time', if: !display_unit do
      expect(accounted_time_element).to have_text(time_unit)
    end

    it "shows accounted time in #{display_unit}", if: display_unit do
      expect(accounted_time_element).to have_text("#{time_unit} #{display_unit}")
    end
  end

  context 'with agent user' do
    context 'with full permissions' do
      let(:user) { create(:agent, groups: [group]) }

      it_behaves_like 'showing accounted time'

      context 'with a pre-defined unit' do
        it_behaves_like 'showing accounted time', 'minute', 'minute(s)'
      end

      context 'with a custom unit' do
        it_behaves_like 'showing accounted time', 'custom', 'person day(s)'
      end
    end

    context 'with read permissions' do
      let(:user) { create(:agent, groups: [group], group_names_access_map: { group.name => 'read' }) }

      it_behaves_like 'showing accounted time'
    end
  end

  context 'with customer user' do
    let(:user)   { create(:customer) }
    let(:ticket) { create(:ticket, customer: user) }

    it 'does not show accounted time' do
      expect(page).to have_no_css('Accounted Time')
    end
  end
end
