# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Checklist', authenticated_as: :authenticate, type: :system do
  let(:ticket) { create(:ticket, group: Group.first) }

  def authenticate
    Setting.set('checklist', true)
    true
  end

  def click_checklist_action(id, action)
    wait.until { page.has_css?(".checklistShow tr[data-id='#{id}'] li[data-table-action='#{action}']", visible: :all) }
    page.find(".checklistShow tr[data-id='#{id}'] .js-action").click
    page.find(".checklistShow tr[data-id='#{id}'] li[data-table-action='#{action}']").click

    true
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
      item_text = SecureRandom.uuid
      click '.js-add'
      expect(page).to have_css('#checklistItemEditText')
      fill_in 'Text or ticket identifier', with: item_text
      click '.js-confirm'
      wait.until { checklist.items.last.text == item_text }
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
end
