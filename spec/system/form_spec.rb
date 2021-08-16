# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Form', type: :system, authenticated_as: true do

  shared_examples 'validating form fields' do
    it 'validate name input' do
      within form_context do
        fill_in 'Email', with: 'discard@znuny.com'
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
        fill_in 'Email', with: 'discard@znuny.com'
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
        sleep 10
        click_on 'Submit'

        expect(page).to have_selector('.has-error [name=email]').and have_no_selector('button[type="submit"][disabled]')
      end
    end
  end

  shared_examples 'submitting valid form fields' do
    it 'submits form filled slowly succesfully' do
      within form_context do
        fill_in 'Name', with: 'some sender'
        fill_in 'Message', with: 'message here'
        fill_in 'Email', with: 'discard@znuny.com'
        sleep 10
        click_on 'Submit'

        expect(page).to have_text('Thank you for your inquiry')
      end
    end

    it 'fails to submit form filled too fast' do
      within form_context do
        fill_in 'Name', with: 'some sender'
        fill_in 'Message', with: 'message here'
        fill_in 'Email', with: 'discard@znuny.com'
        click_on 'Submit'
        accept_alert('Sorry, you look like an robot!')
      end
    end
  end

  context 'with in-app form' do
    let(:path) { 'channels/form' }
    let(:feedback_modal_button) { '.js-formBtn' }

    context 'when form is inline' do
      let(:form_context) { '.js-formInline form.zammad-form' }
      let(:name_input) { '#zammad-form-name-inline' }
      let(:body_input) { '#zammad-form-body-inline' }
      let(:email_input) { '#zammad-form-email-inline' }

      before do
        visit path
        uncheck 'Start modal dialog for form.', { allow_label_click: true }
      end

      it_behaves_like 'validating form fields'
    end

    context 'when form is modal' do
      let(:form_context) { '.js-zammad-form-modal-body form.zammad-form' }
      let(:name_input) { '#zammad-form-name-modal' }
      let(:body_input) { '#zammad-form-body-modal' }
      let(:email_input) { '#zammad-form-email-modal' }

      before do
        visit path
        find(feedback_modal_button).click
      end

      it_behaves_like 'validating form fields'
    end

    it 'shows an inline form' do
      visit path
      uncheck 'Start modal dialog for form.', { allow_label_click: true }
      expect(page).to have_selector('.js-formInline').and have_no_selector('.js-formInline.hide')
    end
  end

  context 'with external form' do
    let(:path) { '/assets/form/form.html' }
    let(:feedback_modal_button) { '#feedback-form-modal' }
    let(:form_inline_selector) { '#feedback-form-inline form.zammad-form' }

    context 'when feature is enabled' do
      before do
        visit 'channels/form'
        check 'form_ticket_create', { allow_label_click: true }
      end

      context 'when form is inline' do
        let(:form_context) { form_inline_selector }
        let(:name_input) { '#zammad-form-name-inline' }
        let(:body_input) { '#zammad-form-body-inline' }
        let(:email_input) { '#zammad-form-email-inline' }

        before { visit path }

        it_behaves_like 'validating form fields'
        it_behaves_like 'submitting valid form fields'
      end

      context 'when form is modal' do
        let(:form_context) { '.js-zammad-form-modal-body form.zammad-form' }
        let(:name_input) { '#zammad-form-name-modal' }
        let(:body_input) { '#zammad-form-body-modal' }
        let(:email_input) { '#zammad-form-email-modal' }

        before do
          visit path
          find(feedback_modal_button).click
        end

        it_behaves_like 'validating form fields'
        it_behaves_like 'submitting valid form fields'
      end
    end

    context 'when feature is disabled' do
      before do
        visit 'channels/form'
        uncheck 'form_ticket_create', { allow_label_click: true }
        visit path
      end

      it 'fails to load form' do
        expect(page).to have_text('Faild to load form config, feature is disabled')
      end
    end
  end
end
