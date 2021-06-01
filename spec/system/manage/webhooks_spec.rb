# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Webhook', type: :system do
  context 'deleting' do
    let!(:webhook) { create(:webhook) }
    let!(:trigger) { create(:trigger, perform: { 'notification.webhook' => { 'webhook_id' => webhook.id.to_s } }) }

    it 'referenced webhook shows error message' do
      visit '/#manage/webhook'

      within :active_content do
        click '.js-action'
        click '.js-delete'
      end

      in_modal disappears: false do
        click '.js-submit'

        expect(page).to have_text('Cannot delete').and(have_text("##{trigger.id}"))
      end
    end
  end
end
