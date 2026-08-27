# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Audit Log', authenticated_as: :admin, type: :system do
  let(:admin) { create(:admin, preferences: { locale: 'de-de' }) }

  context 'with an object type column' do
    let(:knowledge_base) { create(:knowledge_base) }
    let(:role)           { create(:role) }

    let!(:role_audit_log) do
      AuditLog.create!(
        user_id:        admin.id,
        action_type:    'update',
        auditable_type: role.class.name,
        auditable_id:   role.id,
        auditable_name: role.name,
      )
    end

    before do
      AuditLog.create!(
        user_id:        admin.id,
        action_type:    'update',
        auditable_type: knowledge_base.class.name,
        auditable_id:   knowledge_base.id,
        auditable_name: "Knowledge Base ##{knowledge_base.id}",
      )
    end

    it 'shows a humanized, translated object type name in the overview' do
      visit '#system/audit_logs'

      within(:active_content) do
        expect(page).to have_text('Knowledge Base')
        expect(page).to have_no_text('KnowledgeBase')
        expect(page).to have_text('Rolle')
        expect(page).to have_no_text('Role', exact: true)
      end
    end

    it 'keeps the overview sortable by object type' do
      visit '#system/audit_logs'

      within(:active_content) do
        page.first('.js-tableHead[data-column-key=auditable_type]').click
        await_empty_ajax_queue

        expect(page).to have_css('.js-tableBody tr')
        expect(page).to have_text('Rolle')
      end
    end

    it 'translates the object type in the detail dialog too' do
      visit '#system/audit_logs'

      within(:active_content) do
        find("tr[data-id='#{role_audit_log.id}']").click
      end

      in_modal do
        expect(page).to have_field('auditable_type', with: 'Rolle', disabled: true)
      end
    end
  end
end
