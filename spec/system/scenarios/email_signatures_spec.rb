# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_ticket_email_signature_test.rb as end-to-end
#   scenarios: signature handling in the ticket create mask when switching channels
#   and groups (incl. groups without signature) and signature recalculation in the
#   zoom after a pending group change plus removal on discard. Channel switching in
#   the zoom itself is covered by spec/system/ticket/zoom/article_creation_spec.rb.
RSpec.describe 'Scenario > Email signatures', authenticated_as: :authenticate, type: :system do
  let(:signature1) { create(:signature, body: "signature one #{SecureRandom.uuid}") }
  let(:signature2) { create(:signature, body: "signature two #{SecureRandom.uuid}") }
  let(:group1)     { create(:group, name: 'Signature group 1', signature: signature1) }
  let(:group2)     { create(:group, name: 'Signature group 2', signature: signature2) }
  let(:group3)     { create(:group, name: 'Signature group 3') }
  let(:customer)   { create(:customer) }

  def authenticate
    group1 && group2 && group3

    create(:agent, groups: [group1, group2, group3])
  end

  def select_group(group)
    find('[data-attribute-name="group_id"] .js-input').click
    click 'li', text: group.name
  end

  describe 'in the ticket create mask' do
    it 'inserts the signature of the selected group for email tickets only' do
      visit 'ticket/create'

      within(:active_content) do
        find('[name=customer_id_completion]').fill_in with: customer.email

        expect(page).to have_css('.recipientList-entry.js-object')
        first('.recipientList-entry.js-object').click

        find('[name="title"]').fill_in with: 'signature test'
        find('[data-name="body"]').send_keys 'some body 5'

        select_group(group1)

        # Default (non-email) channel: no signature.
        expect(page).to have_no_text(signature1.body)
        expect(page).to have_no_text(signature2.body)

        # The email channel inserts the signature of the selected group.
        find('[data-type=email-out]').click

        expect(page).to have_text(signature1.body)
        expect(page).to have_no_text(signature2.body)

        # Switching the group switches the signature.
        select_group(group2)

        expect(page).to have_text(signature2.body)
        expect(page).to have_no_text(signature1.body)

        # A group without signature removes it entirely, the body stays.
        select_group(group3)

        expect(page).to have_no_text(signature1.body)
        expect(page).to have_no_text(signature2.body)
        expect(page).to have_css('[data-name="body"]', text: 'some body 5')

        # Switching back reinserts the signature.
        select_group(group1)

        expect(page).to have_text(signature1.body)

        # The phone channel removes the signature again.
        find('[data-type=phone-out]').click

        expect(page).to have_no_text(signature1.body)
        expect(page).to have_no_text(signature2.body)
      end
    end
  end

  describe 'in the ticket zoom' do
    let(:ticket)  { create(:ticket, group: group1, customer:) }
    let(:article) { create(:ticket_article, ticket:, type_name: 'email') }

    def authenticate
      article

      create(:agent, groups: [group1, group2, group3])
    end

    it 'recalculates the signature after a pending group change and removes it on discard' do
      visit "#ticket/zoom/#{ticket.id}"

      within(:active_content) do
        first('a[data-type="emailReply"]').click

        expect(page).to have_text(signature1.body)
        expect(page).to have_no_text(signature2.body)

        # An unsaved group change updates the signature used for the next reply.
        find('.sidebar [data-attribute-name="group_id"] .js-input').click
        click 'li', text: group2.name
      end

      await_empty_ajax_queue

      within(:active_content) do
        first('a[data-type="emailReply"]').click

        expect(page).to have_text(signature2.body)
        expect(page).to have_no_text(signature1.body)

        # Discarding the changes removes the signature.
        click '.js-reset'

        expect(page).to have_no_text(signature1.body)
        expect(page).to have_no_text(signature2.body)
      end
    end
  end
end
