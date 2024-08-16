# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Checklist', authenticated_as: :authenticate, type: :system do
  let(:other_agent) { create(:agent, groups: Group.all) }
  let(:ticket)      { create(:ticket, group: Group.first) }

  def authenticate
    Setting.set('checklist', true)
    true
  end

  def perform_item_action(id, action)
    page.find(".checklistShow tr[data-id='#{id}'] .js-action", wait: 0).click
    page.find(".checklistShow tr[data-id='#{id}'] li[data-table-action='#{action}']", wait: 0).click
  rescue => e
    retry_click ||= 5
    retry_click -= 1
    sleep 1
    raise e if retry_click < 1

    retry
  end

  def perform_checklist_action(text)
    click '.sidebar[data-tab=checklist] .js-actions'
    click_on text
  rescue => e
    retry_click ||= 5
    retry_click -= 1
    sleep 1
    raise e if retry_click < 1

    retry
  end

  before do
    visit "#ticket/zoom/#{ticket.id}"
  end

  it 'does show the sidebar for the checklists' do
    expect(page).to have_css('.tabsSidebar-tab[data-tab=checklist]')
    Setting.set('checklist', false)
    expect(page).to have_no_css('.tabsSidebar-tab[data-tab=checklist]')
  end

  it 'does create a checklist' do
    click '.tabsSidebar-tab[data-tab=checklist]'
    expect(page).to have_button('Add empty checklist')
    click_on('Add empty checklist')
    expect(page).to have_no_button('Add empty checklist')
    wait.until { Checklist.where(ticket: ticket).present? }
  end

  it 'does show handle subscriptions for badge when sidebar is not opened' do
    create(:checklist, ticket: ticket)
    expect(page).to have_css(".tabsSidebar-tab[data-tab='checklist'] .js-tabCounter", text: ticket.checklist.items.count)
  end

  context 'when checklist exists' do
    let(:checklist) { create(:checklist, ticket: ticket) }
    let(:item) { checklist.items.last }

    before do
      checklist
      click '.tabsSidebar-tab[data-tab=checklist]'
      wait.until { page.text.include?(checklist.name) }
      await_empty_ajax_queue
    end

    it 'does show handle subscriptions' do
      item.update(text: SecureRandom.uuid)
      expect(page).to have_text(item.text)
      item.destroy
      expect(page).to have_no_text(item.text)

      checklist.destroy
      expect(page).to have_button('Add empty checklist')
    end

    it 'does remove the checklist' do
      perform_checklist_action('Remove checklist')
      click_on 'delete'
      expect(page).to have_text('Add empty checklist')
    end

    it 'does rename the checklist' do
      perform_checklist_action('Rename checklist')
      checklist_name = SecureRandom.uuid
      find('#checklistTitleEditText').fill_in with: checklist_name, fill_options: { clear: :backspace }
      page.find('.js-confirm').click
      wait.until { checklist.reload.name == checklist_name }
    end

    it 'does add item' do
      find('.checklistShowButtons .js-add').click
      wait.until { checklist.items.last.text == '' }
    end

    it 'does check item' do
      perform_item_action(item.id, 'check')

      wait.until { item.reload.checked == true }
    end

    it 'does uncheck item' do
      item.update(checked: true)
      perform_item_action(item.id, 'uncheck')
      wait.until { item.reload.checked == false }
    end

    it 'does edit item' do
      perform_item_action(item.id, 'edit')
      item_text = SecureRandom.uuid
      find(".checklistShow tr[data-id='#{item.id}'] .js-input").fill_in with: item_text, fill_options: { clear: :backspace }
      page.find('.js-confirm').click
      wait.until { item.reload.text == item_text }
    end

    it 'does edit item with a ticket link' do
      perform_item_action(item.id, 'edit')
      item_text = "Ticket##{Ticket.first.number}"
      find(".checklistShow tr[data-id='#{item.id}'] .js-input").fill_in with: item_text, fill_options: { clear: :backspace }
      page.find('.js-confirm').click
      expect(page).to have_link(Ticket.first.title)
    end

    it 'does not abort edit when subscription is updating but including it afterwards' do
      perform_item_action(item.id, 'edit')
      item_text = SecureRandom.uuid
      find(".checklistShow tr[data-id='#{item.id}'] .js-input").fill_in with: item_text, fill_options: { clear: :backspace }

      # simulate other users change
      other_item_text = SecureRandom.uuid
      checklist.items.create!(text: other_item_text, created_by: other_agent, updated_by: other_agent)

      # not really another way to be absolutely sure that this works
      sleep 5

      # the new item will be synced after saving
      expect(page).to have_no_text(other_item_text)

      # it's important that the old edit mode does not abort
      page.find('.js-confirm').click

      # then both items arrive in the UI
      expect(page).to have_text(item_text)
      expect(page).to have_text(other_item_text)
    end

    it 'does delete item' do
      perform_item_action(item.id, 'delete')
      click_on 'delete'
      wait.until { Checklist::Item.find_by(id: item.id).blank? }
    end

    context 'with links' do
      let(:checklist) do
        checklist = create(:checklist, ticket: ticket)
        checklist.items.last.update(text: 'http://google.de test')
        checklist
      end

      it 'does edit item with link' do
        expect(page).to have_link('google.de')
        perform_item_action(item.id, 'edit')
        item_text = SecureRandom.uuid
        find(".checklistShow tr[data-id='#{item.id}'] .js-input").fill_in with: item_text, fill_options: { clear: :backspace }
        page.find('.js-confirm').click
        wait.until { item.reload.text == item_text }
      end
    end

    context 'with ticket links' do
      context 'with access' do
        let(:ticket_link) { create(:ticket, title: SecureRandom.uuid, group: Group.first) }
        let(:checklist) do
          checklist = create(:checklist, ticket: ticket)
          checklist.items.last.update(text: "Ticket##{ticket_link.number}")
          checklist
        end

        it 'does show link to the ticket' do
          expect(page).to have_link(ticket_link.title)
        end
      end

      context 'without access' do
        let(:ticket_link) { create(:ticket, title: SecureRandom.uuid) }
        let(:checklist) do
          checklist = create(:checklist, ticket: ticket)
          checklist.items.last.update(text: "Ticket##{ticket_link.number}")
          checklist
        end

        it 'does show the not authorized for the item' do
          expect(page).to have_text('Not authorized')
        end
      end
    end
  end

  context 'when using a checklist template' do
    let(:checklist_template) { create(:checklist_template) }

    before do
      click '.tabsSidebar-tab[data-tab=checklist]'
      checklist_template
      wait.until { page.find('[name="checklist_template_id"]') }
      await_empty_ajax_queue
    end

    it 'does add checklist from template' do
      expect(page).to have_button('Add from a template')
      expect(page).to have_select('checklist_template_id')

      click_on('Add from a template')
      expect(page).to have_text('Please select a checklist template.')

      select checklist_template.name, from: 'checklist_template_id'
      wait.until { page.has_no_content?('Please select a checklist template.') }
      click_on('Add from a template')

      wait.until { Checklist.where(ticket: ticket).present? }
      expect(Checklist.where(ticket: ticket).last.items.count).to eq(checklist_template.items.count)

      checklist_template.items.each do |item|
        expect(page).to have_text(item.text)
      end
    end
  end

  context 'when checklist modal on submit' do
    let(:checklist) { create(:checklist, ticket: ticket, name: SecureRandom.uuid) }

    def authenticate
      pre_auth
      true
    end

    context 'when activated and set' do
      let(:pre_auth) do
        Setting.set('checklist', true)
        checklist
      end

      it 'does show modal' do
        select 'closed', from: 'State'
        click '.js-submit'
        expect(page).to have_text('You have unchecked items in the checklist')
      end

      it 'does switch to sidebar' do
        select 'closed', from: 'State'
        click '.js-submit'
        page.find('.modal-footer .js-submit').click
        expect(page).to have_text(checklist.name.upcase)
      end

      context 'when ticket is closed' do
        let(:pre_auth) do
          Setting.set('checklist', true)
          checklist
          other_agent

          ticket.update(state: Ticket::State.find_by(name: 'closed'))
        end

        it 'does not show modal' do
          select other_agent.fullname, from: 'Owner'
          click '.js-submit'
          wait.until { ticket.reload.owner.fullname == other_agent.fullname }
          expect(page).to have_no_text('You have unchecked items in the checklist')
        end
      end

      context 'when time accounting is also activated' do
        let(:pre_auth) do
          Setting.set('checklist', true)
          Setting.set('time_accounting', true)
          checklist
        end

        it 'does show both modals' do
          find('.articleNewEdit-body').send_keys('Forwarding with the attachment')
          select 'closed', from: 'State'
          click '.js-submit'
          expect(page.find('.modal-body')).to have_text('You have unchecked items in the checklist')
          page.find('.modal-footer .js-skip').click
          expect(page.find('.modal-body')).to have_text('Accounted Time'.upcase)
          page.find('.modal-footer .js-skip').click
          wait.until { ticket.reload.state.name == 'closed' }
        end
      end
    end

    context 'when deactivated and set' do
      let(:pre_auth) do
        Setting.set('checklist', false)
        checklist
      end

      it 'does not show modal' do
        select 'closed', from: 'State'
        click '.js-submit'
        wait.until { ticket.reload.state.name == 'closed' }
        expect(page).to have_no_text('You have unchecked items in the checklist')
      end
    end

    context 'when activated and completed' do
      let(:pre_auth) do
        Setting.set('checklist', true)
        checklist.items.map { |item| item.update(checked: true) }
      end

      it 'does not show modal' do
        select 'closed', from: 'State'
        click '.js-submit'
        wait.until { ticket.reload.state.name == 'closed' }
        expect(page).to have_no_text('You have unchecked items in the checklist')
      end
    end

    context 'when activated and no checklist' do
      let(:pre_auth) do
        Setting.set('checklist', true)
      end

      it 'does not show modal' do
        select 'closed', from: 'State'
        click '.js-submit'
        wait.until { ticket.reload.state.name == 'closed' }
        expect(page).to have_no_text('You have unchecked items in the checklist')
      end
    end
  end
end
