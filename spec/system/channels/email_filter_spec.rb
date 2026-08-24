# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Channels > Email > Filters', type: :system do
  def open_filter(filter)
    visit '/#channels/email'

    click 'a[href="#c-filter"]'

    within '#c-filter' do
      find('td', text: filter.name).click
    end
  end

  context 'when the filter has a single match condition' do
    let(:filter) do
      create(:postmaster_filter, match: { 'subject' => { 'operator' => 'contains', 'value' => 'important' } })
    end

    before do
      filter
    end

    it 'does not allow removing the last condition' do
      open_filter(filter)

      in_modal do
        within '.postmaster_match' do
          expect(page).to have_css('.js-filterElement', count: 1)
            .and have_css('.js-remove.is-disabled')

          find('.js-remove').click

          expect(page).to have_css('.js-filterElement', count: 1)
        end
      end
    end

    it 'offers all unused attributes for selection' do
      open_filter(filter)

      in_modal do
        within '.postmaster_match' do
          expect(find('.js-attributeSelector select').find(:option, 'From')).not_to be_disabled
        end
      end
    end
  end

  context 'when the filter has multiple match conditions' do
    let(:filter) do
      create(:postmaster_filter, match: {
               'from'    => { 'operator' => 'contains', 'value' => 'example.com' },
               'subject' => { 'operator' => 'contains', 'value' => 'important' },
             })
    end

    before do
      filter
    end

    it 'allows removing all but the last condition' do
      open_filter(filter)

      in_modal do
        within '.postmaster_match' do
          expect(page).to have_css('.js-filterElement', count: 2)
            .and have_no_css('.js-remove.is-disabled')

          first('.js-remove').click

          expect(page).to have_css('.js-filterElement', count: 1)
            .and have_css('.js-remove.is-disabled')

          find('.js-remove').click

          expect(page).to have_css('.js-filterElement', count: 1)
        end
      end
    end
  end
end
