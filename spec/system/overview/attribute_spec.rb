# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Overview with custom attributes', authenticated_as: :authenticate, db_strategy: :reset, type: :system do
  let(:attribute) { create(:object_manager_attribute_boolean) }
  let(:agent)     { create(:agent, groups: [Group.find_by(name: 'Users')]) }
  let(:overview)  { nil }
  let(:ticket)    { nil }

  def authenticate
    agent
    attribute
    ObjectManager::Attribute.migration_execute
    overview
    ticket

    true
  end

  before do
    visit "ticket/view/#{overview.link}"
  end

  context 'when the custom attribute used in a view in an overview' do
    let(:overview) do
      create(:overview,
             view: { s:                 ['title', 'number', attribute.name],
                     view_mode_default: 's' })
    end

    it 'shows the custom attribute display description' do
      within :active_content do
        expect(page).to have_text attribute.display.to_s.upcase
      end
    end
  end

  context 'when the custom attribute is used as condition in an overview' do
    let(:overview) do
      create(:overview,
             condition: { "ticket.#{attribute.name}" => { operator: 'is', value: true } },
             view:      { s:                 ['title', 'number', attribute.name],
                          view_mode_default: 's' })
    end

    context 'with no ticket with custom attribute value true' do
      it 'shows no entries' do
        within :active_content do
          expect(page).to have_text 'NO ENTRIES'
        end
      end
    end

    context 'with a ticket with custom attribute value true' do
      let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users'), attribute.name => true) }

      it 'shows the ticket' do
        within :active_content do
          expect(page).to have_text attribute.display.to_s.upcase
          expect(page).to have_text ticket.title
        end
      end
    end
  end
end
