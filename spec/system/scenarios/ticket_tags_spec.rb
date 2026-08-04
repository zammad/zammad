# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_ticket_tag_test.rb as end-to-end scenarios: tag
#   commit behavior in the create mask (tab/blur), tag handling in the zoom sidebar
#   (enter/blur commit, tags with spaces, comma separated input, removal), live
#   propagation into a second session, admin rename/delete effects on tickets and
#   the enforcement of the tag_new=off setting.
RSpec.describe 'Scenario > Ticket tags', authenticated_as: :authenticate, type: :system do
  let(:group)    { Group.find_by(name: 'Users') }
  let(:agent)    { create(:agent, password: 'test', groups: [group]) }
  let(:customer) { create(:customer) }
  let(:ticket)   { create(:ticket, group:, customer:) }

  def authenticate
    agent
  end

  def add_zoom_tag(name, commit: :enter)
    click '.content.active .js-newTagLabel'

    input = find('.content.active .js-newTagInput')
    input.fill_in with: name

    if commit == :enter
      input.send_keys(:enter)
    else
      find('#global-search').click
    end
  end

  describe 'tags in the create mask' do
    it 'commits tags via tab and blur and persists them on the created ticket' do
      visit 'ticket/create'

      within(:active_content) do
        find('[name=customer_id_completion]').fill_in with: customer.email

        expect(page).to have_css('.recipientList-entry.js-object')
        first('.recipientList-entry.js-object').click

        find('[name="title"]').fill_in with: 'tag commit test'
        find('[data-name="body"]').send_keys 'tag commit test body'

        # The group is auto-assigned: the agent has access to a single group only.

        # Tab commits the comma separated tags...
        tags_input = find('input[name="tags"] ~ input.token-input')
        tags_input.fill_in with: 'tag1, tag2'
        tags_input.send_keys(:tab)

        expect(page).to have_css('.token', text: 'tag1')
        expect(page).to have_css('.token', text: 'tag2')

        # ...losing the focus commits as well.
        find('input[name="tags"] ~ input.token-input').fill_in with: 'tag3'
      end

      find('#global-search').click

      within(:active_content) do
        expect(page).to have_css('.token', text: 'tag3')

        click '.js-submit'
      end

      expect(page).to have_css('.content.active .ticketZoom')
      expect(page).to have_css('.content.active .js-tag', text: 'tag1')
      expect(page).to have_css('.content.active .js-tag', text: 'tag2')
      expect(page).to have_css('.content.active .js-tag', text: 'tag3')
      expect(page).to have_no_css('.content.active .js-tag', text: 'tag4')
    end
  end

  describe 'tags in the zoom sidebar' do
    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'adds and removes tags and propagates them into a second session' do
      # Enter commit, tags with spaces and comma separated multi input.
      add_zoom_tag('tag1')
      expect(page).to have_css('.content.active .js-tag', text: 'tag1')

      add_zoom_tag('tag 2')
      expect(page).to have_css('.content.active .js-tag', text: 'tag 2')

      add_zoom_tag('tag3, tag4')
      expect(page).to have_css('.content.active .js-tag', text: 'tag3')
      expect(page).to have_css('.content.active .js-tag', text: 'tag4')

      # Blur commit.
      add_zoom_tag('tag5', commit: :blur)
      expect(page).to have_css('.content.active .js-tag', text: 'tag5')

      # A second session (of another agent, to avoid the session takeover dialog)
      #   on the same ticket sees the tags without interaction.
      using_session(:second_browser) do
        login(username: create(:agent, password: 'test', groups: [group]).login, password: 'test')

        visit "#ticket/zoom/#{ticket.id}"

        expect(page).to have_css('.content.active .js-tag', text: 'tag 2')
        expect(page).to have_css('.content.active .js-tag', text: 'tag5')
      end

      # The tags survive a reload.
      page.refresh

      expect(page).to have_css('.content.active .js-tag', text: 'tag1')
      expect(page).to have_css('.content.active .js-tag', text: 'tag5')

      # Removing a tag updates the ticket and the second session.
      within('.content.active .tags .list-item', text: 'tag1') do
        find('.js-delete', visible: :all).click
      end

      expect(page).to have_no_css('.content.active .js-tag', text: 'tag1')
      expect(ticket.reload.tag_list).not_to include('tag1')

      using_session(:second_browser) do
        expect(page).to have_no_css('.content.active .js-tag', text: 'tag1')
      end
    end
  end

  describe 'admin tag changes affect tickets' do
    def authenticate
      %w[tag3 tag5].each { |tag| ticket.tag_add(tag, 1) }

      create(:admin, groups: [group])
    end

    it 'renaming and deleting tags in the admin area updates the ticket' do
      visit 'manage/tags'

      within(:active_content) do
        find('td', text: 'tag3').click
      end

      in_modal do
        fill_in 'name', with: 'TAGXX'

        click_on 'Submit'
      end

      within(:active_content) do
        within 'tr', text: 'tag5' do
          find('.js-delete', visible: :all).click
        end
      end

      in_modal do
        click_on 'Yes'
      end

      visit "#ticket/zoom/#{ticket.id}"

      expect(page).to have_css('.content.active .js-tag', text: 'TAGXX')
      expect(page).to have_no_css('.content.active .js-tag', text: 'tag3')
      expect(page).to have_no_css('.content.active .js-tag', text: 'tag5')
    end
  end

  describe 'with disabled tag_new setting' do
    def authenticate
      Setting.set('tag_new', false)
      Tag::Item.lookup_by_name_and_create('tagexisting')

      agent
    end

    it 'accepts existing tags but rejects new ones in the zoom sidebar' do
      visit "#ticket/zoom/#{ticket.id}"

      add_zoom_tag('tagexisting')
      expect(page).to have_css('.content.active .js-tag', text: 'tagexisting')

      add_zoom_tag('tagnotexisting')
      expect(page).to have_no_css('.content.active .js-tag', text: 'tagnotexisting')

      # The rejection is persistent, not only visual.
      page.refresh

      expect(page).to have_css('.content.active .js-tag', text: 'tagexisting')
      expect(page).to have_no_css('.content.active .js-tag', text: 'tagnotexisting')
      expect(ticket.reload.tag_list).to eq(['tagexisting'])
    end
  end
end
