# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Taskbar > Draft after a reload', app: :desktop_view, authenticated_as: :agent, type: :system do
  let(:group)          { create(:group) }
  let(:agent)          { create(:agent, groups: [group], roles: [Role.find_by(name: 'Agent'), kb_editor_role]) }
  let(:kb_editor_role) { create(:role, permission_names: %w[knowledge_base.editor]) }

  def wait_for_stored_draft(title)
    wait.until { Taskbar.where(user_id: agent.id).any? { |taskbar| taskbar.state.to_s.include?(title) } }
  end

  def wait_for_input_value(label, value)
    wait.until { find_input(label).input_element.value == value }
  end

  it 'restores a ticket create draft after a reload' do
    visit '/ticket/create'
    wait_for_form_to_settle('ticket-create')

    within_form(form_updater_gql_number: 1) do
      find_input('Title').type('Draft ticket title')
    end

    wait_for_stored_draft('Draft ticket title')

    refresh
    wait_for_form_to_settle('ticket-create')

    wait_for_input_value('Title', 'Draft ticket title')
  end

  context 'with a knowledge base' do
    let(:knowledge_base) { create(:knowledge_base) }
    let(:locale)         { knowledge_base.kb_locales.first.system_locale.locale }

    before { create(:knowledge_base_category, knowledge_base:) }

    it 'restores a knowledge base answer create draft after a reload' do
      visit "/knowledge-base/locale/#{locale}/answer/create"
      wait_for_form_to_settle('knowledge-base-answer-create')

      within_form(form_updater_gql_number: 1) do
        find_input('Title').type('Draft answer title')
      end

      wait_for_stored_draft('Draft answer title')

      refresh
      wait_for_form_to_settle('knowledge-base-answer-create')

      wait_for_input_value('Title', 'Draft answer title')
    end
  end
end
