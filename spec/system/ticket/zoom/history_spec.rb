# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > History', authenticated_as: :authenticate, time_zone: 'Europe/London', type: :system do
  describe 'Log Trigger and Scheduler in Ticket History #4604' do
    let(:ticket)  { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:trigger) { create(:trigger, condition: { 'ticket.action' => { 'operator' => 'is', 'value' => 'create' } }, perform: { 'ticket.title'=>{ 'value'=>'triggered' } }, activator: 'action', execution_condition_mode: 'selective') }

    def authenticate
      ticket && trigger
      TransactionDispatcher.commit
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does show the changes of the trigger in the history' do
      click '.sidebar-header-headline'
      click 'li[data-type=ticket-history]'
      expect(page).to have_text("Trigger: #{trigger.name}")
      expect(page).to have_text('triggered')
    end
  end

  describe 'Ticket history shows html when updating articles #5168' do
    let(:old_body) { SecureRandom.uuid }
    let(:new_body) { SecureRandom.uuid }
    let(:ticket)   { create(:ticket, group: Group.first) }
    let(:article)  { create(:ticket_article, ticket: ticket, body: "<div><b>#{old_body}</b></div>", content_type: 'text/html') }

    def authenticate
      article.update(body: "<div><b>#{new_body}</b></div>")
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does not show html in the ticket history', :aggregate_failures do
      click '.sidebar-header-headline'
      click 'li[data-type=ticket-history]'
      expect(page).to have_text(old_body)
      expect(page).to have_text(new_body)
      expect(page).to have_no_text('<div>')
      expect(page).to have_no_text('</div>')
    end
  end
end
