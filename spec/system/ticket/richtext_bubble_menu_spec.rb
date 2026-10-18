# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Richtext Bubble Menu', authenticated_as: :authenticate, type: :system do
  let(:agent)                    { create(:agent) }
  let(:ai_provider)              { 'zammad_ai' }
  let(:ai_assistance_text_tools) { true }
  let(:ui_richtext_bubble_menu)  { true }
  let(:input)                    { 'Teh qwik braun foxx jumpz ova da laizi doge.' }
  let(:output)                   { Struct.new(:content, :stored_result, :ai_analytics_run, :fresh).new(content: 'The quick brown fox jumps over the lazy dog.', stored_result: nil, ai_analytics_run: create(:ai_analytics_run), fresh: false) }
  let(:text_tool_name)           { Faker::Lorem.unique.sentence }

  def authenticate
    skip('does not work with Chromium-based drivers') if %i[zammad_chrome zammad_playwright zammad_playwright_mobile].include?(Capybara.current_driver)

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
    allow_any_instance_of(Service::AI::Feature::TextTool).to receive(:execute).and_return(output)
  end

  shared_examples 'showing text tools dropdown and replacing selected text' do
    it 'shows text tools dropdown and replaces selected text' do
      set_editor_field_value('body', input)

      # Wait for the taskbar update to finish.
      taskbar_timestamp = Taskbar.last.updated_at
      wait.until { Taskbar.last.updated_at != taskbar_timestamp }

      find("[data-name='body']").send_keys([magic_key, 'a'])

      expect(page).to have_css('.bubble-menu[role=menu]')

      find("[aria-label='AI Writing Assistant Tools']").click
      find('.js-action', text: text_tool_name).click

      in_modal do
        expect(page).to have_css('h1', text: "AI Writing Assistant: #{text_tool_name}")
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
          .and have_no_css('.bubble-menu-item[aria-label="AI Writing Assistant Tools"]')
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
          .and have_no_css('.bubble-menu-item[aria-label="AI Writing Assistant Tools"]')
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

    def select_editor_field
      # Wait for the taskbar update to finish.
      taskbar_timestamp = Taskbar.last.updated_at
      wait.until { Taskbar.last.updated_at != taskbar_timestamp }

      find("[data-name='body']").send_keys([magic_key, 'a'])

      expect(page).to have_css('.bubble-menu[role=menu]')
    end

    it 'inserts a link' do
      prepare_and_select

      find("[aria-label='Insert link']").click

      in_modal do
        find('input[name="link"]').set('example.com')
        click_on 'Link'
      end

      within("[data-name='body']") do
        expect(page).to have_css('a[href="http://example.com"]', text: 'Format Me')
      end
    end

    it 'updates an existing link' do
      set_editor_field_richtext_value('body', '<a href="http://old.example.com">Format Me</a>')
      select_editor_field

      find("[aria-label='Insert link']").click

      in_modal do
        expect(find('input[name="link"]').value).to eq('http://old.example.com')
        find('input[name="link"]').set('new.example.com')
        click_on 'Update'
      end

      within("[data-name='body']") do
        expect(page).to have_css('a[href="http://new.example.com"]', text: 'Format Me')
      end
    end

    it 'links a selection containing both linked and plain text' do
      set_editor_field_richtext_value('body', '<a href="http://old.example.com">Linked</a> plain')
      select_editor_field

      find("[aria-label='Insert link']").click

      in_modal do
        expect(find('input[name="link"]').value).to eq('')
        expect(page).to have_no_css('.js-remove')

        find('input[name="link"]').set('example.com')
        click_on 'Link'
      end

      within("[data-name='body']") do
        expect(page).to have_link('Linked', href: 'http://example.com')
          .and have_link('plain', href: 'http://example.com')
          .and have_no_link(href: 'http://old.example.com')
      end
    end

    it 'applies the URL to every link in the selection' do
      set_editor_field_richtext_value('body', '<a href="http://first.example.com">First</a> and <a href="http://second.example.com">second</a>')
      select_editor_field

      find("[aria-label='Insert link']").click

      in_modal do
        expect(find('input[name="link"]').value).to eq('')

        find('input[name="link"]').set('example.com')
        click_on 'Link'
      end

      within("[data-name='body']") do
        expect(page).to have_link('First', href: 'http://example.com')
          .and have_link('and', href: 'http://example.com')
          .and have_link('second', href: 'http://example.com')
          .and have_no_link(href: 'http://first.example.com')
          .and have_no_link(href: 'http://second.example.com')
      end
    end

    it 'removes a link' do
      set_editor_field_richtext_value('body', '<a href="http://example.com">Format Me</a>')
      select_editor_field

      find("[aria-label='Insert link']").click

      in_modal do
        click_on 'Remove'
      end

      within("[data-name='body']") do
        expect(page).to have_no_css('a')
          .and have_text('Format Me')
      end
    end

    it 'rejects an empty link URL' do
      prepare_and_select

      find("[aria-label='Insert link']").click

      in_modal do
        find('input[name="link"]').set(' ')
        click_on 'Link'

        expect(page).to have_css('.modal-alerts-container .alert--danger', text: 'Enter link URL')
          .and have_css('input[name="link"]')
      end

      within("[data-name='body']") do
        expect(page).to have_no_css('a[href="http://"]')
      end
    end

    it 'mangles a javascript link URL client-side' do
      prepare_and_select

      find("[aria-label='Insert link']").click

      in_modal do
        find('input[name="link"]').set('javascript:alert(1)')
        click_on 'Link'
      end

      within("[data-name='body']") do
        expect(page).to have_css('a[href^="http://javascript:"]', text: 'Format Me')
      end
    end

    it 'links a cross-block selection without wrapping block elements' do
      set_editor_field_richtext_value('body', '<p>First paragraph</p><p>Second paragraph</p>')
      select_editor_field

      find("[aria-label='Insert link']").click

      in_modal do
        find('input[name="link"]').set('example.com')
        click_on 'Link'
      end

      within("[data-name='body']") do
        expect(page).to have_css('a[href="http://example.com"]')
          .and have_no_css('a > p')
          .and have_text('First paragraph')
          .and have_text('Second paragraph')
      end
    end

    context 'when using the signature edit modal' do
      before do
        visit 'channels/email'

        click 'a[href="#c-signature"]'
      end

      def open_new_signature_modal
        find('[data-type=new]').click
      end

      context 'when dismissing a link dialog' do
        let(:agent) { create(:admin) }

        before do
          open_new_signature_modal

          in_modal(disappears: false) do
            find('input[name="name"]').fill_in with: 'Unsaved signature'
            set_editor_field_value('body', 'Signature body')
            find("[data-name='body']").send_keys([magic_key, 'a'])

            find("[aria-label='Insert link']").click
          end
        end

        it 'keeps the signature open on Escape and restores its Escape handler' do
          expect(page).to have_css('.modal.in.modal--ready', count: 2)

          find('input[name="link"]').send_keys(:escape)

          expect(page).to have_no_field('link', visible: :all)
            .and have_css('.modal.in.modal--ready', count: 1)
            .and have_css('[data-name="body"]:focus')

          in_modal do
            expect(find('input[name="name"]').value).to eq('Unsaved signature')
            expect(find("[data-name='body']")).to have_text('Signature body')

            accept_confirm do
              find("[data-name='body']").send_keys(:escape)
            end
          end

          expect(page).to have_no_css('.modal.in')
        end

        it 'restores the signature dialog after cancelling the link dialog' do
          expect(page).to have_css('.modal.in.modal--ready', count: 2)

          within(find('input[name="link"]').ancestor('.modal')) do
            click_on 'Cancel & Go Back'
          end

          expect(page).to have_no_field('link', visible: :all)
            .and have_css('.modal.in.modal--ready', count: 1)
            .and have_css('[data-name="body"]:focus')

          in_modal do
            expect(find('input[name="name"]').value).to eq('Unsaved signature')

            click_on 'Submit'
          end

          expect(Signature.find_by(name: 'Unsaved signature').body).to have_text('Signature body')
        end
      end

      it 'shows the bubble menu on the signature body, inserts a link and saves it' do
        open_new_signature_modal

        in_modal do
          find('div[data-name="name"] input').fill_in with: 'Bubble menu signature'
          set_editor_field_value('body', 'Signature body')

          find("[data-name='body']").send_keys([magic_key, 'a'])

          expect(page).to have_css('.bubble-menu[role=menu]')

          find("[aria-label='Insert link']").click
        end

        find('input[name="link"]').set('example.com')
        click_on 'Link'

        in_modal do
          within('[data-name="body"]') do
            expect(page).to have_css('a[href="http://example.com"]', text: 'Signature body')
          end
          click_on 'Submit'
        end

        expect(Signature.find_by(name: 'Bubble menu signature').body)
          .to have_css('a[href="http://example.com"]', text: 'Signature body')
      end

      it 'shows the bubble menu on the signature body again after the modal is reopened' do
        2.times do
          open_new_signature_modal

          in_modal do
            find('div[data-name="name"] input').fill_in with: 'Bubble menu signature'
            set_editor_field_value('body', 'Signature body')

            find("[data-name='body']").send_keys([magic_key, 'a'])

            expect(page).to have_css('.bubble-menu[role=menu]')

            click_on 'Cancel & Go Back'
          end
        end
      end
    end
  end
end
