# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Form', authenticated_as: true, type: :system do

  shared_examples 'validating form fields' do
    it 'validate name input' do
      within form_context do
        fill_in 'Email', with: 'discard@discard.zammad.org'
        fill_in 'Message', with: 'message here'
        click_on 'Submit'

        expect(page).to have_validation_message_for(name_input)
      end
    end

    it 'validate email input' do
      within form_context do
        fill_in 'Name', with: 'some sender'
        fill_in 'Message', with: 'message here'
        click_on 'Submit'

        expect(page).to have_validation_message_for(email_input)
      end
    end

    it 'validate message input' do
      within form_context do
        fill_in 'Name', with: 'some sender'
        fill_in 'Email', with: 'discard@discard.zammad.org'
        click_on 'Submit'

        expect(page).to have_validation_message_for(body_input)
      end
    end

    it 'validate email format' do
      within form_context do
        fill_in 'Name', with: 'some sender'
        fill_in 'Email', with: 'invalidformat'
        click_on 'Submit'

        expect(page).to have_validation_message_for(email_input)
      end
    end

    it 'validate email field with non existing domain space' do
      within form_context do
        fill_in 'Name', with: 'some sender'
        fill_in 'Message', with: 'message here'
        fill_in 'Email', with: 'somebody@notexistinginanydomainspacealsonothere.nowhere'

        click_on 'Submit'

        expect(page).to have_css('.has-error [name=email]').and have_no_button(type: 'submit', disabled: true)
      end
    end
  end

  shared_examples 'submitting valid form fields' do
    it 'submits the form successfully' do
      within form_context do
        fill_in 'Name', with: 'some sender'
        fill_in 'Message', with: 'message here'
        fill_in 'Email', with: 'discard@discard.zammad.org'
        click_on 'Submit'

        expect(page).to have_text('Thank you for your inquiry')
      end
    end
  end

  shared_examples 'submitting fails due to throttling' do
    it 'rejects form submission due to throttling' do
      within form_context do
        fill_in 'Name', with: 'some sender'
        fill_in 'Message', with: 'message here'
        fill_in 'Email', with: 'discard@discard.zammad.org'
        # Avoid await_empty_ajax_queue.
        execute_script('$("button:submit").trigger("click")')
        accept_alert('The form could not be submitted!')
      end
    end
  end

  context 'when settings are changed' do
    let(:path)  { 'channels/form' }
    let(:group) { create(:group) }

    before do
      group
      visit path
    end

    it 'stores settings correctly' do
      set_tree_select_value('group_id', group.name)

      check_input_field_value('group_id', group.id.to_s, visible: :all)

      wait_for_setting('form_ticket_create_group_id', group.id.to_s)
    end
  end

  context 'with in-app form' do
    let(:path)                  { 'channels/form' }
    let(:feedback_modal_button) { '.js-formBtn' }

    context 'when form is inline' do
      let(:form_context) { '.js-formInline form.zammad-form' }
      let(:name_input)  { '#zammad-form-name-inline' }
      let(:body_input)  { '#zammad-form-body-inline' }
      let(:email_input) { '#zammad-form-email-inline' }

      before do
        visit path
        uncheck 'Start modal dialog for form.', allow_label_click: true
      end

      it_behaves_like 'validating form fields'
    end

    context 'when form is modal' do
      let(:form_context) { '.js-zammad-form-modal-body form.zammad-form' }
      let(:name_input)  { '#zammad-form-name-modal' }
      let(:body_input)  { '#zammad-form-body-modal' }
      let(:email_input) { '#zammad-form-email-modal' }

      before do
        visit path
        find(feedback_modal_button).click
      end

      it_behaves_like 'validating form fields'
    end

    it 'shows an inline form' do
      visit path
      uncheck 'Start modal dialog for form.', allow_label_click: true
      expect(page).to have_css('.js-formInline').and have_no_selector('.js-formInline.hide')
    end
  end

  context 'with external form' do
    let(:path)                  { '/assets/form/form.html' }
    let(:feedback_modal_button) { '#feedback-form-modal' }
    let(:form_inline_selector)  { '#feedback-form-inline form.zammad-form' }

    context 'when feature is enabled' do
      before do
        visit 'channels/form'
        check 'form_ticket_create', allow_label_click: true
        wait_for_setting('form_ticket_create', true)
      end

      context 'when form is inline' do
        let(:form_context) { form_inline_selector }
        let(:name_input)  { '#zammad-form-name-inline' }
        let(:body_input)  { '#zammad-form-body-inline' }
        let(:email_input) { '#zammad-form-email-inline' }

        before { visit path }

        it_behaves_like 'validating form fields'
        it_behaves_like 'submitting valid form fields'
      end

      context 'when form is modal' do
        let(:form_context) { '.js-zammad-form-modal-body form.zammad-form' }
        let(:name_input)  { '#zammad-form-name-modal' }
        let(:body_input)  { '#zammad-form-body-modal' }
        let(:email_input) { '#zammad-form-email-modal' }

        before do
          visit path
          find(feedback_modal_button).click
        end

        it_behaves_like 'validating form fields'
        it_behaves_like 'submitting valid form fields'
      end

      context 'when form is throttled with :too_many_requests' do
        before do
          Setting.set('form_ticket_create_by_ip_per_hour', 0)
          visit path
        end

        let(:form_context) { form_inline_selector }
        let(:name_input)  { '#zammad-form-name-inline' }
        let(:body_input)  { '#zammad-form-body-inline' }
        let(:email_input) { '#zammad-form-email-inline' }

        it_behaves_like 'submitting fails due to throttling'
      end

      context 'with honeypot protection' do
        let(:form_context) { form_inline_selector }
        let(:honeypot)     { "#{form_inline_selector} input[name='#{FormSpamProtection::Honeypot::FIELD_NAME}']" }

        before do
          Setting.set('form_ticket_create_honeypot', true)
          visit path
        end

        it 'injects the off-screen honeypot field into the form' do
          expect(page).to have_css(honeypot, visible: :all)
        end

        it 'rejects a submission that fills the honeypot field' do
          within form_context do
            fill_in 'Name', with: 'some sender'
            fill_in 'Email', with: 'discard@discard.zammad.org'
            fill_in 'Message', with: 'message here'
          end

          # the field is off-screen, so set it the way an automated client would
          execute_script("document.querySelector(\"#{honeypot}\").value = 'http://spam.example.com'")

          # Avoid await_empty_ajax_queue.
          execute_script('$("button:submit").trigger("click")')
          accept_alert('Your submission could not be verified. Please make sure you completed any verification challenge and try again.')

          expect(page).to have_no_text('Thank you for your inquiry')
        end
      end

      context 'with a CAPTCHA provider configured' do
        let(:form_context) { form_inline_selector }

        context 'when it renders a widget (Turnstile)' do
          before do
            Setting.set('form_ticket_create_captcha_provider', 'turnstile')
            Setting.set('form_ticket_create_captcha_options', { 'sitekey' => 'site', 'secret' => 'secret' })
            visit path
          end

          it 'injects the widget container with the configured site key' do
            expect(page).to have_css("#{form_inline_selector} .cf-turnstile[data-sitekey='site']", visible: :all)
          end
        end

        context 'when it is ALTCHA (server-issued challenge)' do
          before do
            Setting.set('form_ticket_create_captcha_provider', 'altcha')
            visit path
          end

          it 'injects the widget pointed at the challenge endpoint', :aggregate_failures do
            expect(page).to have_css("#{form_inline_selector} altcha-widget", visible: :all)

            challenge = find("#{form_inline_selector} altcha-widget", visible: :all)['challenge']
            expect(challenge).to end_with('/form_captcha_challenge')
          end
        end
      end
    end

    context 'when feature is disabled' do
      before do
        visit 'channels/form'
        uncheck 'form_ticket_create', allow_label_click: true
        wait_for_setting('form_ticket_create', false)
        visit path
      end

      it 'fails to load form' do
        expect(page).to have_text('Faild to load form config, feature is disabled')
      end
    end
  end
end
