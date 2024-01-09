# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Time Accounting', authenticated_as: :authenticate, type: :system do
  let(:time_accounting) { true }

  def authenticate
    Setting.set('time_accounting', time_accounting)

    true
  end

  before do
    visit '/#manage/time_accounting'
  end

  context 'when toggling the switch' do
    before do
      within :active_content do
        click '.js-header-switch'
      end
    end

    context 'with the feature disabled' do
      let(:time_accounting) { false }

      it 'turns the feature on' do
        expect(Setting.get('time_accounting')).to be(true)
      end
    end

    it 'turns the feature off' do
      expect(Setting.get('time_accounting')).to be(false)
    end
  end

  context 'when configuring settings' do
    context 'with ticket selector setting' do
      before do
        within :active_content do
          find('.js-filterElement .js-attributeSelector select')
            .find('option', text: 'Priority')
            .select_option

          find('.js-filterElement .js-value select')
            .find('option', text: '3 high')
            .select_option

          click_on 'Save'
        end
      end

      it 'updates time_accounting_selector setting' do
        expect(Setting.get('time_accounting_selector'))
          .to eq({
                   'condition' => {
                     'ticket.priority_id' => {
                       'operator' => 'is',
                       'value'    => ['3'],
                     },
                   },
                 })
      end

      it 'does not have expert mode' do
        within :active_content do
          expect(page).to have_no_css('.ticket_selector .js-switch')
        end
      end
    end

    context 'with time unit setting' do
      before do
        within :active_content do
          find('#timeAccountingUnit')
            .find('option', text: unit)
            .select_option

          if custom_unit.present?
            find('#timeAccountingCustomUnit').fill_in with: custom_unit
          end

          click_on 'Save'
        end
      end

      shared_examples 'updating time_accounting_unit* settings' do
        it 'updates time_accounting_unit* settings' do
          if custom_unit.empty?
            expect(page).to have_no_css('#timeAccountingCustomUnit')
          end

          expect(Setting.get('time_accounting_unit')).to eq(unit)
          expect(Setting.get('time_accounting_unit_custom')).to eq(custom_unit)
        end
      end

      context 'with a pre-defined unit' do
        let(:unit)        { 'minute' }
        let(:custom_unit) { '' }

        it_behaves_like 'updating time_accounting_unit* settings'
      end

      context 'with a custom unit' do
        let(:unit)        { 'custom' }
        let(:custom_unit) { 'person day(s)' }

        it_behaves_like 'updating time_accounting_unit* settings'
      end
    end
  end

  context 'with activity types' do
    before do
      within :active_content do
        click_on 'Activity Types'
      end
    end

    context 'with feature setting' do
      before do
        within :active_content do
          find('#timeAccountingTypes')
            .find('option', text: setting_option)
            .select_option

          click_on 'Save'
        end
      end

      shared_examples 'updating time_accounting_types setting' do
        it 'updates time_accounting_types setting' do
          expect(Setting.get('time_accounting_types')).to be(setting_state)
        end
      end

      context 'when enabling the type selection' do
        let(:setting_option) { 'yes' }
        let(:setting_state)  { true }

        it_behaves_like 'updating time_accounting_types setting'
      end

      context 'when disabling the type selection' do
        let(:setting_option) { 'no' }
        let(:setting_state)  { false }

        def authenticate
          Setting.set('time_accounting_types', true)

          true
        end

        it_behaves_like 'updating time_accounting_types setting'
      end
    end

    context 'with new activity type form' do
      let(:name) { Faker::Name.unique.name }

      before do
        within :active_content do
          click_on 'New Activity Type'
        end

        in_modal do
          fill_in 'Name', with: name

          click_on 'Submit'
        end
      end

      it 'supports adding new activity types' do
        expect(page).to have_css('.js-tableBody tr.item td', exact_text: name)
      end
    end

    context 'with edit activity type form' do
      let(:activity_type) { create(:ticket_time_accounting_type) }
      let(:new_name)      { Faker::Name.unique.name }

      def authenticate
        activity_type

        true
      end

      before do
        within :active_content do
          find('tr', text: activity_type.name).click
        end

        in_modal do
          fill_in 'Name', with: new_name

          click_on 'Submit'
        end
      end

      it 'supports editing existing activity types' do
        expect(page).to have_css(".js-tableBody tr.item[data-id='#{activity_type.id}'] td", exact_text: new_name)
      end
    end

    context 'with actions' do
      let(:activity_type) { create(:ticket_time_accounting_type) }

      def authenticate
        activity_type

        true
      end

      before do
        within :active_content do
          row = find('tr', text: activity_type.name)
          row.find('.js-action').click
        end
      end

      context 'with set as default action' do
        before do
          within :active_content do
            row = find('tr', text: activity_type.name)
            row.find('.js-set-as-default').click
          end

          in_modal do
            click_on 'Yes'
          end
        end

        it 'supports setting activity type as default' do
          expect(page).to have_css(".js-tableBody tr.item[data-id='#{activity_type.id}'] td", text: 'Default')
        end
      end

      context 'with unset default action' do
        def authenticate
          Setting.set('time_accounting_type_default', activity_type.id)

          true
        end

        before do
          within :active_content do
            row = find('tr', text: activity_type.name)
            row.find('.js-unset-default').click
          end

          in_modal do
            click_on 'Yes'
          end
        end

        it 'supports unsetting activity type as default' do
          expect(page).to have_no_css(".js-tableBody tr.item[data-id='#{activity_type.id}'] td", text: 'Default')
        end
      end
    end
  end

  context 'with accounted time' do
    def authenticate
      create_list(:ticket_time_accounting, count)

      true
    end

    before do
      within :active_content do
        click_on 'Accounted Time'
      end
    end

    context 'with less than 20 entries' do
      let(:count) { 10 }

      it 'shows all entries' do
        expect(find_all('.js-tableActivity tbody tr').count).to eq(count)
        expect(page).to have_no_text('Only the 20 most recent records are displayed. Download to view the full list.')
      end
    end

    context 'with more than 21 entries' do
      let(:count) { 21 }

      it 'shows the first 20 entries' do
        expect(find_all('.js-tableActivity tbody tr').count).to eq(20)
        expect(page).to have_text('Only the 20 most recent records are displayed. Download to view the full list.')
      end
    end
  end
end
