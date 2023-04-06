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

  context 'when checking custom payload validation' do
    it 'shows error message' do
      visit '/#manage/webhook'

      within :active_content do
        click 'a[data-type="new"]'
      end

      in_modal do
        fill_in 'name', with: 'Test'
        fill_in 'endpoint', with: 'https://example.com/webhook'

        click 'a[data-toggle="collapse"]'
        wait.until do
          expect(page).to have_field('Custom Payload', type: 'textarea')
        end

        fill_in 'custom_payload', with: 'invalid json'
        click '.js-submit'

        expect(page).to have_css('div[data-attribute-name="custom_payload"].has-error')
          .and have_text('Please enter a valid JSON string.')
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
