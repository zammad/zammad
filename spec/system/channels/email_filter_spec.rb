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

  context 'when there are more than 500 filters', authenticated_as: :authenticate do
    def authenticate
      create_list(:postmaster_filter, 500)
      create(:postmaster_filter, name: 'AAA newest filter')
      true
    end

    it 'shows also the filters beyond the first 500' do
      visit '/#channels/email'

      click 'a[href="#c-filter"]'

      within '#c-filter' do
        expect(page).to have_css('td', text: 'AAA newest filter')
      end
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

  context 'when matching the email urgency' do
    it 'offers exactly the accepted values and saves the condition' do
      visit '/#channels/email'
      click 'a[href="#c-filter"]'
      click '.content.active a[data-type="new"]'

      in_modal do
        fill_in 'name', with: 'Urgent mail'

        within '.postmaster_match' do
          find('.js-attributeSelector select').find(:option, 'Email urgency').select_option

          expect(find('.js-operator select').all('option').map(&:value)).to eq(['is any of', 'is none of'])
          expect(find('select[name="match::email-urgency::value"]').all('option').map(&:value)).to eq(%w[high normal low])

          find('select[name="match::email-urgency::value"]').find(:option, 'High urgency').select_option
        end

        click '.js-submit'
      end

      expect(page).to have_no_css('.modal')
      expect(PostmasterFilter.find_by(name: 'Urgent mail').match)
        .to eq('email-urgency' => { 'operator' => 'is any of', 'value' => ['high'] })

      within '#c-filter' do
        find('td', text: 'Urgent mail').click
      end

      in_modal do
        within '.postmaster_match' do
          expect(find('.js-operator select').value).to eq('is any of')
          expect(find('select[name="match::email-urgency::value"]').value).to eq(['high'])
        end
      end
    end

    it 'keeps the selected value when the operator is switched' do
      visit '/#channels/email'
      click 'a[href="#c-filter"]'
      click '.content.active a[data-type="new"]'

      in_modal do
        fill_in 'name', with: 'Urgent mail'

        within '.postmaster_match' do
          find('.js-attributeSelector select').find(:option, 'Email urgency').select_option
          find('select[name="match::email-urgency::value"]').find(:option, 'High urgency').select_option
          find('.js-operator select').find(:option, 'is none of').select_option

          expect(find('select[name="match::email-urgency::value"]').value).to eq(['high'])
        end

        click '.js-submit'
      end

      expect(page).to have_no_css('.modal')
      expect(PostmasterFilter.find_by(name: 'Urgent mail').match)
        .to eq('email-urgency' => { 'operator' => 'is none of', 'value' => ['high'] })
    end
  end

  context 'when setting email or url attributes from regex captures', db_strategy: :reset do
    %w[email url].each do |type|
      it "saves the placeholder into the #{type} attribute" do
        attribute = create_attribute(:object_manager_attribute_text, name: "regexp_#{type}", display: "Regexp #{type}",
                                     data_option: { 'type' => type, 'maxlength' => 200, 'null' => true })

        visit '/#channels/email'
        click 'a[href="#c-filter"]'
        click '.content.active a[data-type="new"]'

        in_modal do
          fill_in 'name', with: "Filter #{type}"
          fill_in 'match::from::value', with: 'target'

          within '.postmaster_set' do
            find(".js-attributeSelector select option[value='x-zammad-ticket-#{attribute.name}']").select_option
          end

          fill_in "perform::x-zammad-ticket-#{attribute.name}::value", with: '#{regexp.order}' # rubocop:disable Lint/InterpolationCheck
          click '.js-submit'
        end

        expect(page).to have_no_css('.modal')
        expect(PostmasterFilter.find_by(name: "Filter #{type}").perform)
          .to include("x-zammad-ticket-#{attribute.name}" => include('value' => '#{regexp.order}')) # rubocop:disable Lint/InterpolationCheck
      end
    end
  end
end
