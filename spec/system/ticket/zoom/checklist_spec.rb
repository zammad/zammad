# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Checklist', authenticated_as: :authenticate, type: :system do
  let(:ticket) { create(:ticket, group: Group.first) }

  def authenticate
    Setting.set('checklist', true)
    true
  end

  def click_checklist_action(id, action)
    page.find(".checklistShow tr[data-id='#{id}'] .js-action", wait: 0).click
    page.find(".checklistShow tr[data-id='#{id}'] li[data-table-action='#{action}']", wait: 0).click
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

    it 'does add item' do
      find('.checklistShowButtons .js-add').click
      wait.until { checklist.items.last.text == '' }
    end

    it 'does check item' do
      click_checklist_action(item.id, 'check')

      wait.until { item.reload.checked == true }
    end

    it 'does uncheck item' do
      item.update(checked: true)
      click_checklist_action(item.id, 'uncheck')
      wait.until { item.reload.checked == false }
    end

    it 'does edit item' do
      click_checklist_action(item.id, 'edit')
      item_text = SecureRandom.uuid
      find(".checklistShow tr[data-id='#{item.id}'] .js-input").fill_in with: item_text, fill_options: { clear: :backspace }
      page.find('.js-confirm').click
      wait.until { item.reload.text == item_text }
    end

    it 'does delete item' do
      click_checklist_action(item.id, 'delete')
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
        click_checklist_action(item.id, 'edit')
        item_text = SecureRandom.uuid
        find(".checklistShow tr[data-id='#{item.id}'] .js-input").fill_in with: item_text, fill_options: { clear: :backspace }
        page.find('.js-confirm').click
        wait.until { item.reload.text == item_text }
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
      expect(page).to have_no_text('Please select a checklist template.')
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
