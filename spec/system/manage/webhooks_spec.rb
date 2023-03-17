# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Webhook', type: :system do

  context 'when showing the example payload' do

    it 'shows correctly' do
      visit '/#manage/webhook'

      within :active_content do
        click 'a[data-type="payload"]'
      end

      in_modal do
        expect(page).to have_text('X-Zammad-Trigger:')
      end
    end
  end

  context 'when deleting' do
    let!(:webhook) { create(:webhook) }
    let!(:trigger) { create(:trigger, perform: { 'notification.webhook' => { 'webhook_id' => webhook.id.to_s } }) }

    it 'referenced webhook shows error message' do
      visit '/#manage/webhook'

      within :active_content do
        click '.js-action'
        click '.js-delete'
      end

      in_modal do
        click '.js-submit'

        expect(page).to have_text('Cannot delete').and(have_text("##{trigger.id}"))
      end
    end
  end
end
