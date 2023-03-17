# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Channels > Form', type: :system do
  before do
    visit '/#channels/form'
  end

  context 'when looking at the default screen' do
    it 'has correct default settings' do
      within :active_content, 'table.settings-list' do
        # Enable debugging for implementation.
        expect(page).to have_unchecked_field(name: 'debug', visible: :all, disabled: :all)

        # Show title in form.
        expect(page).to have_unchecked_field(name: 'showTitle', visible: :all, disabled: :all)

        # Start modal dialog for form.
        expect(page).to have_checked_field(name: 'modal', visible: :all, disabled: :all)

        # Don't load CSS for form. You need to generate your own CSS for the form.
        expect(page).to have_unchecked_field(name: 'noCSS', visible: :all, disabled: :all)

        # Add attachment option to upload.
        expect(page).to have_unchecked_field(name: 'attachmentSupport', visible: :all, disabled: :all)

        # Add agreement text before submit.
        expect(page).to have_unchecked_field(id: 'agreementSupport', visible: :all, disabled: :all)
      end
    end
  end

  context 'when adding agreement text' do
    context 'when agreement text is checked' do
      let(:default_agreement_text) { 'Accept Data Privacy Policy & Acceptable Use Policy' }

      before do
        check 'Add agreement text before submit.', allow_label_click: true
      end

      shared_examples 'showing agreement text' do
        it 'shows the agreement text' do
          within :active_content, 'table.settings-list' do
            expect(page).to have_text agreement_text
          end

          within :active_content, 'code.js-paramsBlock' do
            expect(page).to have_text agreement_text
          end
        end

        it 'shows the agreement text on the modal form' do
          within :active_content, '.browser.js-browser' do
            find('.js-formBtn').click
          end

          within '.zammad-form-modal .js-zammad-form-modal-body' do
            within '.zammad-form' do
              expect(page).to have_text %r{#{agreement_text}}i
            end
          end
        end

        it 'shows the agreement text on the inline form' do
          within :active_content, 'table.settings-list' do
            uncheck 'modal', allow_label_click: true
          end

          scroll_into_view('.zammad-form')

          within '.js-formInline.browser-inline-form' do
            expect(page).to have_text %r{#{agreement_text}}i
          end
        end
      end

      context 'with default agreement text' do
        let(:agreement_text) { default_agreement_text }

        it_behaves_like 'showing agreement text'
      end

      context 'when agreement text is changed' do
        let(:agreement_text) { 'New agreement text' }

        before do
          within :active_content, 'table.settings-list' do
            # The click is needed to get the focus back to the field for chrome.
            find(:richtext, 'agreementMessage').click

            find(:richtext, 'agreementMessage').send_keys agreement_text
          end
        end

        it_behaves_like 'showing agreement text'
      end
    end
  end
end
