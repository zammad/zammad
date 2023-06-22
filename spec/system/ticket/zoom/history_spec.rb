# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
end
