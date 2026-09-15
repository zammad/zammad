# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System > Packages', type: :system do
  let(:package) do
    Package.create!(
      name:          'Zammad Test Package',
      version:       '1.0.0',
      vendor:        'Zammad Foundation',
      state:         'installed',
      created_by_id: 1,
      updated_by_id: 1,
    )
  end

  context 'when running in a container environment' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ZAMMAD_DOCKER').and_return('true')
    end

    it 'shows the navigation entry and a read-only overview' do
      visit 'system/package'

      within '.sidebar' do
        expect(page).to have_link('Packages', href: '#system/package')
      end

      within :active_content do
        expect(page).to have_css('.page-header-title h1', text: 'Packages')
        expect(page).to have_text('This page gives you an overview of the packages currently installed in your Zammad instance.')
        expect(page).to have_text('In container-based environments, packages are managed as part of the deployment and cannot be installed or removed from here.')
        expect(page).to have_no_css('.js-packageSettings')
        expect(page).to have_no_css('.js-fileUpload')
        expect(page).to have_no_button('Install Package')
        expect(page).to have_no_text('Available packages')
      end
    end

    it 'shows the empty placeholder without packages' do
      visit 'system/package'

      within :active_content do
        expect(page).to have_css('.table--placeholder', text: %r{No Entries}i)
      end
    end

    context 'with an installed package' do
      before { package }

      it 'lists the package without an action column' do
        visit 'system/package'

        within :active_content do
          expect(page).to have_css('tr[data-id]', text: package.name)
          expect(page).to have_css('tr[data-id]', text: package.version)
          expect(page).to have_no_css('.package-action-header')
          expect(page).to have_no_css('.package-action-cell')
        end
      end
    end
  end

  context 'when running outside a container environment' do
    before { package }

    it 'shows the page with all actions' do
      visit 'system/package'

      within :active_content do
        expect(page).to have_css('.page-header-title h1', text: 'Packages')
        expect(page).to have_css('.js-packageSettings', text: 'Configure')
        expect(page).to have_css('.js-fileUpload')
        expect(page).to have_button('Install Package', disabled: true)
        expect(page).to have_css('.package-action-header', text: %r{Action}i)
        expect(page).to have_css('tr[data-id] .package-action-cell')
      end
    end
  end
end
