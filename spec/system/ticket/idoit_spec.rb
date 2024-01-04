# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Handling with i-doit', integration: true, required_envs: %w[IDOIT_API_TOKEN IDOIT_API_ENDPOINT IDOIT_API_CATEGORY], type: :system do

  let(:api_endpoint) { ENV['IDOIT_API_ENDPOINT'] }
  let(:api_category) { ENV['IDOIT_API_CATEGORY'] }

  before do
    Setting.set('idoit_integration', true)
    Setting.set('idoit_config', { api_token: ENV['IDOIT_API_TOKEN'], endpoint: api_endpoint, client_id: '' })
  end

  def open_idoit_sidebar
    find('.tabsSidebar svg.icon-printer').click
  end

  def select_entry_in_sidebar
    find('.sidebar[data-tab="idoit"] .js-headline').click
    find('.sidebar[data-tab="idoit"] .dropdown-menu').click
    entry_id = nil

    in_modal do
      find('form input.js-input').click
      find("form li.js-option[data-display-name='#{api_category}']").click
      entry_id = find('form.js-result tbody tr:first-child input').tap(&:click).value
      # submit the i-doit object selections
      find('form button.js-submit').click
    end

    entry_id
  end

  context 'when using the i-doit integration' do
    let(:agent) { create(:agent, groups: [Group.find_by(name: 'Users')]) }

    before do
      visit 'ticket/create'
      find('[name=customer_id_completion]').fill_in with: 'nico'
      page.find('li.recipientList-entry.js-object.is-active').click
      fill_in 'Title', with: 'subject - i-doit integration'
      set_editor_field_value('body', 'body - i-doit integration')
    end

    it 'does process i-doit information correctly', authenticated_as: :agent do

      within :active_content do
        # Select an item initially.
        open_idoit_sidebar
        entry_id = select_entry_in_sidebar
        item_link = ".sidebar[data-tab='idoit'] a[href='#{api_endpoint}/?objID=#{entry_id}']"
        expect(page).to have_css(item_link)

        # Reselect the customer and verify if object is still shown in sidebar.
        find('[name=customer_id_completion]').fill_in with: 'admin'
        page.find('li.recipientList-entry.js-object.is-active').click
        expect(page).to have_css(item_link)

        # Submit the ticket.
        find('.newTicket button.js-submit').click
        open_idoit_sidebar
        expect(page).to have_css(item_link)

        # Check it's still there after reload.
        page.refresh
        open_idoit_sidebar
        expect(page).to have_css(item_link)

        # Delete the item.
        find(".sidebar[data-tab='idoit'] .js-delete[data-object-id=\"#{entry_id}\"]").click
        expect(find(".sidebar[data-tab='idoit']")).to have_text('none')

        # Check if the item is still gone after reload.
        page.refresh
        open_idoit_sidebar
        expect(find(".sidebar[data-tab='idoit']")).to have_text('none')
      end
    end
  end
end
