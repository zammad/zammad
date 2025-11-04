# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket create > Inline Image Replacement for AI Text Tools', authenticated_as: :authenticate, type: :system do
  let(:group) { Group.first }
  let(:agent) { create(:agent, groups: [group]) }

  let(:ticket_article_body) do
    body = 'This is a funny text with multiple images:<br>'

    body += '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAF0lEQVR4nGP8z0AaYCJR/aiGUQ1DSAMAQC4BH2bjRnMAAAAASUVORK5CYII=" alt="Red 16x16"><br>'
    body += '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAGUlEQVR4nGNkYPjPQApgIkn1qIZRDUNKAwA+MAEfWiW9ygAAAABJRU5ErkJggg==" alt="Blue 16x16"><br>'

    body
  end

  let(:ai_service_text_tool_result) do
    Struct.new(:content, :stored_result, :ai_analytics_run, :fresh, keyword_init: true).new(
      content:          'This is a funny text with multiple images:<br>[[IMAGE_PLACEHOLDER_1]]<br>[[IMAGE_PLACEHOLDER_2]]<br>(AI EDITED)',
      stored_result:    nil,
      ai_analytics_run: create(:ai_analytics_run),
      fresh:            false,
    )
  end

  def authenticate
    skip('Bubble menu does not work when using Chrome.') if Capybara.current_driver == :zammad_chrome

    allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(true)

    setup_ai_provider
    Setting.set('ai_assistance_text_tools', true)
    Setting.set('ui_richtext_bubble_menu', true)

    AI::TextTool.destroy_all
    create(:ai_text_tool, name: 'Dummy', instruction: 'Make it nice.')

    agent
  end

  before do
    visit 'ticket/create'
  end

  context 'when inline images are used' do
    it 'sends placeholders to the AI service and does not remove inline images' do
      within :active_content do
        set_editor_field_richtext_value('body', ticket_article_body)

        # Wait for the taskbar update to finish.
        taskbar_timestamp = Taskbar.last.updated_at
        wait.until { Taskbar.last.updated_at != taskbar_timestamp }

        find("[data-name='body']").send_keys([magic_key, 'a'])

        expect(page).to have_css('.bubble-menu[role=menu]')

        ai_service_spy = instance_spy(Service::AIAssistance::TextTools)
        allow(Service::AIAssistance::TextTools).to receive(:new).and_return(ai_service_spy)
        allow(ai_service_spy).to receive(:execute).and_return(ai_service_text_tool_result)

        find("[aria-label='Writing Assistant Tools']").click
        find('.js-action', text: 'Dummy').click

        expect(Service::AIAssistance::TextTools).to have_received(:new).with(
          hash_including(
            input: 'This is a funny text with multiple images:<br>[[IMAGE_PLACEHOLDER_1]]<br>[[IMAGE_PLACEHOLDER_2]]<br>',
          )
        )

        in_modal do
          click_on 'Approve'
        end

        check_editor_field_richtext_value('body', "#{ticket_article_body}(AI EDITED)")
      end
    end
  end
end
