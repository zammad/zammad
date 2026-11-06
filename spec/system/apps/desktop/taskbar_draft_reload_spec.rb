# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Taskbar > Draft after a reload', app: :desktop_view, authenticated_as: :agent, type: :playwright do
  let(:group)          { create(:group) }
  let(:agent)          { create(:agent, groups: [group], roles: [Role.find_by(name: 'Agent'), kb_editor_role]) }
  let(:kb_editor_role) { create(:role, permission_names: %w[knowledge_base.editor]) }

  def wait_for_stored_draft(title)
    wait_until("No taskbar stores the draft #{title}") do
      Taskbar.where(user_id: agent.id).any? { |taskbar| taskbar.state.to_s.include?(title) }
    end
  end

  it 'restores a ticket create draft after a reload' do
    open_desktop('/ticket/create')
    wait_for_form_to_settle('ticket-create')

    fill_field('Title', 'Draft ticket title')
    wait_for_stored_draft('Draft ticket title')

    reload_page
    wait_for_form_to_settle('ticket-create')

    expect(field('Title').get_by_role('textbox')).to have_value('Draft ticket title')
  end

  context 'with a knowledge base' do
    let(:knowledge_base) { create(:knowledge_base) }
    let(:locale)         { knowledge_base.kb_locales.first.system_locale.locale }

    before { create(:knowledge_base_category, knowledge_base:) }

    it 'restores a knowledge base answer create draft after a reload' do
      open_desktop("/knowledge-base/locale/#{locale}/answer/create")
      wait_for_form_to_settle('knowledge-base-answer-create')

      fill_field('Title', 'Draft answer title')
      wait_for_stored_draft('Draft answer title')

      reload_page
      wait_for_form_to_settle('knowledge-base-answer-create')

      expect(field('Title').get_by_role('textbox')).to have_value('Draft answer title')
    end
  end
end
