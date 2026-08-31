# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Handling with Snipe-IT', integration: true, required_envs: %w[SNIPEIT_API_TOKEN SNIPEIT_API_ENDPOINT SNIPEIT_API_SEARCH], type: :system do

  let(:api_endpoint) { ENV['SNIPEIT_API_ENDPOINT'] }
  let(:api_search)   { ENV['SNIPEIT_API_SEARCH'] }

  before do
    Setting.set('snipeit_integration', true)
    Setting.set('snipeit_config', { api_token: ENV['SNIPEIT_API_TOKEN'], endpoint: api_endpoint, verify_ssl: false })

    # Wait up to 2 minutes for the Snipe-IT container to become fully responsive.
    # The container may need extra time to initialize its database on first run.
    wait(120).until do
      Snipeit.verify(ENV['SNIPEIT_API_TOKEN'], api_endpoint)
      true
    rescue
      false
    end
  end

  def open_snipeit_sidebar
    find('.tabsSidebar svg.icon-printer').click
  end

  def select_asset_in_sidebar
    find('.sidebar[data-tab="snipeit"] .js-headline').click
    find('.sidebar[data-tab="snipeit"] .dropdown-menu').click
    asset_id = nil

    in_modal do
      find('form.js-search input.js-searchField').fill_in with: api_search
      asset_id = find('form.js-result tbody tr:first-child input[name=asset_id]').tap(&:click).value
      # submit the Snipe-IT asset selections
      find('button.js-submit').click
    end

    asset_id
  end

  context 'when using the Snipe-IT integration' do
    let(:agent) { create(:agent, groups: [Group.find_by(name: 'Users')]) }

    before do
      visit 'ticket/create'
      find('[name=customer_id_completion]').fill_in with: 'nico'
      page.find('li.recipientList-entry.js-object.is-active').click
      fill_in 'Title', with: 'subject - Snipe-IT integration'
      set_editor_field_value('body', 'body - Snipe-IT integration')
    end

    it 'does process Snipe-IT information correctly', authenticated_as: :agent do

      within :active_content do
        # Select an asset initially.
        open_snipeit_sidebar
        asset_id = select_asset_in_sidebar
        item_link = ".sidebar[data-tab='snipeit'] a[href='#{api_endpoint}/hardware/#{asset_id}']"
        expect(page).to have_css(item_link)

        # Reselect the customer and verify the asset is still shown in the sidebar.
        find('[name=customer_id_completion]').fill_in with: 'admin'
        page.find('li.recipientList-entry.js-object.is-active').click
        expect(page).to have_css(item_link)

        # Submit the ticket.
        find('.newTicket button.js-submit').click
        open_snipeit_sidebar
        expect(page).to have_css(item_link)

        # Check it's still there after reload.
        page.refresh
        open_snipeit_sidebar
        expect(page).to have_css(item_link)

        # Delete the asset.
        find(".sidebar[data-tab='snipeit'] .js-delete[data-asset-id=\"#{asset_id}\"]").click
        expect(find(".sidebar[data-tab='snipeit']")).to have_text('none')

        # Check if the asset is still gone after reload.
        page.refresh
        open_snipeit_sidebar
        expect(find(".sidebar[data-tab='snipeit']")).to have_text('none')
      end
    end
  end
end
