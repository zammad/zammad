# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Profile > Language', type: :system do
  let(:group)        { create(:group) }
  let(:session_user) { create(:admin, preferences: { locale: locale }, groups: Group.all) }
  let(:path)         { 'profile/language' }

  shared_examples 'having translated content in' do |current_element|
    it "the '#{current_element}' element" do
      within current_element do
        expect(page).to have_text(translated_content)
      end
    end
  end

  shared_examples 'having translated content in the page title' do
    it 'shows the translated content' do
      expect(page).to have_title(translated_content)
    end
  end

  shared_examples 'displaying the current language' do
    it 'shows the current language' do
      within :active_content do
        within '.page-content' do
          expect(page).to have_field(with: full_current_locale)
        end
      end
    end
  end

  shared_examples 'have translations in ticket page' do |translated_element|
    it_behaves_like 'having translated content in the page title'

    context 'when translated content is ticket priority' do
      let(:translated_content) { priority }

      it_behaves_like 'having translated content in', translated_element
    end

    context 'when translated content is ticket owner' do
      let(:translated_content) { owner }

      it_behaves_like 'having translated content in', translated_element
    end

    context 'when translated content is ticket title' do
      let(:translated_content) { title }

      it_behaves_like 'having translated content in', :active_content
    end
  end

  context 'when user locale is English (en-gb)', authenticated_as: :session_user do
    let(:locale)              { 'en-gb' }
    let(:translated_content)  { 'Overview' }
    let(:full_current_locale) { 'English (Great Britain)' }
    let(:priority)            { 'PRIORITY' }
    let(:owner)               { 'OWNER' }

    before do
      visit path
      # Suppress the modal dialog that invites to contributions for translations that are < 90% as this breaks the tests for de-de.
      page.evaluate_script "App.LocalStorage.set('translation_support_no', true, App.Session.get('id'))"
    end

    it_behaves_like 'displaying the current language'

    it_behaves_like 'having translated content in', '.js-menu'

    context 'when profile language is changed' do
      let(:new_locale) { 'de-de' }
      let(:full_current_locale) { 'Deutsch' }

      before do
        within :active_content do
          within '.page-content' do
            find('input.searchableSelect-main.js-input').click
            find("[data-value=#{new_locale}].js-option").click

            click_button
            session_user.reload
          end
        end
      end

      it 'changes the user preference language' do
        expect(session_user.preferences[:locale]).to eq(new_locale)
      end

      it_behaves_like 'displaying the current language'
    end

    context 'with language page visited' do
      let(:translated_content) { 'Language' }

      it_behaves_like 'having translated content in', '.page-header'
      it_behaves_like 'having translated content in', '.sidebar.NavBarProfile'
    end

    context 'with dashboard page visited' do
      let(:path)               { 'dashboard' }
      let(:translated_content) { 'My Stats' }

      it_behaves_like 'having translated content in', :active_content
    end

    context 'with overview page visited' do
      let(:path) { 'ticket/view' }
      let(:translated_content) { 'My Assigned Tickets' }

      it_behaves_like 'having translated content in the page title'
      it_behaves_like 'having translated content in', :active_content
    end

    context 'with drafted ticket create' do
      let(:path) { 'ticket/create' }
      let(:title)              { 'preferences lang check #1' }
      let(:customer)           { 'nicole' }
      let(:translated_content) { "Inbound Call: #{title}" }

      translated_element = '.newTicket .ticket-create'

      before do
        fill_in 'title', with: title
        fill_in 'customer_id_completion', with: customer
        send_keys(:enter, :tab)
        find('[data-name="body"]').set(title)
        select 'Users', from: 'group_id'
      end

      include_examples 'have translations in ticket page', translated_element
    end

    context 'with ticket zoom page' do
      let(:path) { "ticket/zoom/#{ticket.id}" }
      let(:title)              { 'preferences lang check #2' }
      let(:translated_content) { title }
      let(:user_group)         { Group.lookup(name: 'Users') }
      let(:ticket)             { create(:ticket, group: user_group, title: title) }

      translated_element = '.content.active .sidebar-content'

      include_examples 'have translations in ticket page', translated_element
    end
  end

  context 'when user locale is Deutsch', authenticated_as: :session_user do
    let(:locale) { 'de-de' }
    let(:translated_content)  { 'Übersichten' }
    let(:full_current_locale) { 'Deutsch' }
    let(:priority)            { 'PRIORITÄT' }
    let(:owner)               { 'BESITZER' }

    before do
      visit path
      # Suppress the modal dialog that invites to contributions for translations that are < 90% as this breaks the tests for de-de.
      page.evaluate_script "App.LocalStorage.set('translation_support_no', true, App.Session.get('id'))"
    end

    it_behaves_like 'displaying the current language'

    it_behaves_like 'having translated content in', '.js-menu'

    context 'when profile language is changed' do
      let(:new_locale) { 'en-gb' }
      let(:full_current_locale) { 'English (Great Britain)' }
      let(:translated_content)  { 'Übersichten' }

      before do
        within :active_content do
          within '.page-content' do
            find('input.searchableSelect-main.js-input').click
            find("[data-value=#{new_locale}].js-option").click

            click_button
            session_user.reload
          end
        end
      end

      it 'changes the user preference language' do
        expect(session_user.preferences[:locale]).to eq(new_locale)
      end

      it_behaves_like 'displaying the current language'
    end

    context 'with language page visited' do
      let(:translated_content) { 'Sprache' }

      it_behaves_like 'having translated content in', '.page-header'
      it_behaves_like 'having translated content in', '.sidebar.NavBarProfile'
    end

    context 'with dashboard page visited' do
      let(:path)               { 'dashboard' }
      let(:translated_content) { 'Meine Statistik' }

      it_behaves_like 'having translated content in', :active_content
    end

    context 'with overview page visited' do
      let(:path) { 'ticket/view' }
      let(:translated_content) { Translation.translate('de-de', 'My Assigned Tickets') }

      it_behaves_like 'having translated content in the page title'
      it_behaves_like 'having translated content in', :active_content
    end

    context 'with drafted ticket create' do
      let(:path) { 'ticket/create' }
      let(:title)              { 'preferences lang check #1' }
      let(:customer)           { 'nicole' }
      let(:translated_content) { "Eingehender Anruf: #{title}" }

      translated_element = '.newTicket .ticket-create'

      before do
        fill_in 'title', with: title
        fill_in 'customer_id_completion', with: customer
        send_keys(:enter, :tab)
        find('[data-name="body"]').set(title)
        select 'Users', from: 'group_id'
      end

      include_examples 'have translations in ticket page', translated_element
    end

    context 'with ticket zoom page' do
      let(:path) { "ticket/zoom/#{ticket.id}" }
      let(:title)              { 'preferences lang check #2' }
      let(:translated_content) { title }
      let(:user_group)         { Group.lookup(name: 'Users') }
      let(:ticket)             { create(:ticket, group: user_group, title: title) }

      translated_element = '.content.active .sidebar-content'

      include_examples 'have translations in ticket page', translated_element
    end
  end
end
