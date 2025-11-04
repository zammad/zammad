# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Richtext Bubble Menu', authenticated_as: :authenticate, type: :system do
  let(:agent)                    { create(:agent) }
  let(:ai_provider)              { 'zammad_ai' }
  let(:ai_assistance_text_tools) { true }
  let(:ui_richtext_bubble_menu)  { true }
  let(:input)                    { 'Teh qwik braun foxx jumpz ova da laizi doge.' }
  let(:output)                   { Struct.new(:content, :stored_result, :ai_analytics_run, :fresh, keyword_init: true).new(content: 'The quick brown fox jumps over the lazy dog.', stored_result: nil, ai_analytics_run: create(:ai_analytics_run), fresh: false) }
  let(:text_tool_name)           { Faker::Lorem.unique.sentence }

  def authenticate
    skip('does not work with chrome driver') if Capybara.current_driver == :zammad_chrome

    allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(true)

    if ai_provider
      setup_ai_provider(ai_provider)
    else
      unset_ai_provider
    end

    Setting.set('ai_assistance_text_tools', ai_assistance_text_tools)
    Setting.set('ui_richtext_bubble_menu', ui_richtext_bubble_menu)

    create(:ai_text_tool, name: text_tool_name, instruction: 'Do something with the following text:')

    agent
  end

  before do
    allow_any_instance_of(AI::Service::TextTool).to receive(:execute).and_return(output)
  end

  shared_examples 'showing text tools dropdown and replacing selected text' do
    it 'shows text tools dropdown and replaces selected text' do
      set_editor_field_value('body', input)

      # Wait for the taskbar update to finish.
      taskbar_timestamp = Taskbar.last.updated_at
      wait.until { Taskbar.last.updated_at != taskbar_timestamp }

      find("[data-name='body']").send_keys([magic_key, 'a'])

      expect(page).to have_css('.bubble-menu[role=menu]')

      find("[aria-label='Writing Assistant Tools']").click
      find('.js-action', text: text_tool_name).click

      in_modal do
        expect(page).to have_css('h1', text: "Writing Assistant: #{text_tool_name}")
          .and have_text(input)
          .and have_text(output[:content])

        click_on 'Approve'
      end

      check_editor_field_value('body', output[:content])
    end
  end

  shared_examples 'not showing text tools button' do
    context 'when ai provider is not set' do
      let(:ai_provider) { false }

      it 'does not show text tools button' do
        set_editor_field_value('body', input)

        # Wait for the taskbar update to finish.
        taskbar_timestamp = Taskbar.last.updated_at
        wait.until { Taskbar.last.updated_at != taskbar_timestamp }

        find("[data-name='body']").send_keys([magic_key, 'a'])

        expect(page).to have_css('.bubble-menu[role=menu]')
          .and have_no_css('.bubble-menu-item[aria-label="Writing Assistant Tools"]')
      end
    end

    context 'when bubble menu flag is not set' do
      let(:ui_richtext_bubble_menu) { false }

      it 'does not show bubble menu' do
        set_editor_field_value('body', input)

        # Wait for the taskbar update to finish.
        taskbar_timestamp = Taskbar.last.updated_at
        wait.until { Taskbar.last.updated_at != taskbar_timestamp }

        find("[data-name='body']").send_keys([magic_key, 'a'])

        expect(page).to have_no_css('.bubble-menu[role=menu]')
      end
    end

    context 'when ai_assistance_text_tools flag is not set' do
      let(:ai_assistance_text_tools) { false }

      it 'does not show text tools button' do
        set_editor_field_value('body', input)

        # Wait for the taskbar update to finish.
        taskbar_timestamp = Taskbar.last.updated_at
        wait.until { Taskbar.last.updated_at != taskbar_timestamp }

        find("[data-name='body']").send_keys([magic_key, 'a'])

        expect(page).to have_css('.bubble-menu[role=menu]')
          .and have_no_css('.bubble-menu-item[aria-label="Writing Assistant Tools"]')
      end
    end
  end

  context 'when using ticket create' do
    before do
      visit 'ticket/create'
    end

    it_behaves_like 'showing text tools dropdown and replacing selected text'

    context 'when text tools are disabled' do
      let(:ai_assistance_text_tools) { false }

      it_behaves_like 'not showing text tools button'
    end
  end

  context 'when using ticket zoom' do
    let(:agent)   { create(:agent, groups: [ticket.group]) }
    let(:ticket)  { create(:ticket) }
    let(:article) { create(:ticket_article, ticket:) }

    before do
      article

      visit "ticket/zoom/#{ticket.id}"

      find('.article-new').click

      # Wait till input box expands completely.
      find('.attachmentPlaceholder-label').in_fixed_position
    end

    it_behaves_like 'showing text tools dropdown and replacing selected text'

    context 'when text tools are disabled' do
      let(:ai_assistance_text_tools) { false }

      it_behaves_like 'not showing text tools button'
    end
  end

  context 'when using formatting actions via bubble menu' do
    before do
      visit 'ticket/create'
    end

    def prepare_and_select(text = 'Format Me')
      set_editor_field_value('body', text)

      # Wait for the taskbar update to finish.
      taskbar_timestamp = Taskbar.last.updated_at
      wait.until { Taskbar.last.updated_at != taskbar_timestamp }

      find("[data-name='body']").send_keys([magic_key, 'a'])

      expect(page).to have_css('.bubble-menu[role=menu]')
    end

    it 'applies bold' do
      prepare_and_select

      find("[aria-label='Format as bold']").click

      within("[data-name='body']") do
        expect(page).to have_css('b', text: 'Format Me')
      end
    end

    it 'applies italic' do
      prepare_and_select

      find("[aria-label='Format as italic']").click

      within("[data-name='body']") do
        expect(page).to have_css('i', text: 'Format Me')
      end
    end

    it 'applies underline' do
      prepare_and_select

      find("[aria-label='Format as underlined']").click

      within("[data-name='body']") do
        expect(page).to have_css('u', text: 'Format Me')
      end
    end

    it 'applies strikethrough' do
      prepare_and_select

      find("[aria-label='Format as strikethrough']").click

      within("[data-name='body']") do
        expect(page).to have_css('strike', text: 'Format Me')
      end
    end

    it 'removes inline formatting' do
      prepare_and_select

      find("[aria-label='Format as bold']").click

      within("[data-name='body']") do
        expect(page).to have_css('b', text: 'Format Me')
      end

      find("[aria-label='Remove formatting']").click

      within("[data-name='body']") do
        expect(page).to have_no_css('b')
          .and have_text('Format Me')
      end
    end

    it 'toggles Heading 1' do
      prepare_and_select

      find("[aria-label='Heading 1']").click

      within("[data-name='body']") do
        expect(page).to have_css('h1', text: 'Format Me')
      end
    end

    it 'toggles Heading 2' do
      prepare_and_select

      find("[aria-label='Heading 2']").click

      within("[data-name='body']") do
        expect(page).to have_css('h2', text: 'Format Me')
      end
    end

    it 'toggles Heading 3' do
      prepare_and_select

      find("[aria-label='Heading 3']").click

      within("[data-name='body']") do
        expect(page).to have_css('h3', text: 'Format Me')
      end
    end

    it 'creates an ordered list' do
      prepare_and_select

      find("[aria-label='Add ordered list']").click

      within("[data-name='body']") do
        expect(page).to have_css('ol > li', text: 'Format Me')
      end
    end

    it 'creates a bullet list' do
      prepare_and_select

      find("[aria-label='Add unordered list']").click

      within("[data-name='body']") do
        expect(page).to have_css('ul > li', text: 'Format Me')
      end
    end
  end
end
