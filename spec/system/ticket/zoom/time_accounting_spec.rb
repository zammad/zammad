# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Time Accounting', authenticated_as: :authenticate, type: :system do
  let(:ticket)                      { create(:ticket, group: Group.find_by(name: 'Users')) }
  let(:article_body)                { Faker::Hacker.unique.say_something_smart }
  let(:time_unit)                   { Faker::Number.unique.decimal(l_digits: 1, r_digits: 1) }
  let(:time_accounting_unit)        { nil }
  let(:time_accounting_unit_custom) { nil }
  let(:time_accounting_types)       { false }
  let(:active_type)                 { create(:ticket_time_accounting_type) }
  let(:inactive_type)               { create(:ticket_time_accounting_type, active: false) }

  def authenticate
    Setting.set('time_accounting', true)
    Setting.set('time_accounting_types', time_accounting_types)
    Setting.set('time_accounting_unit', time_accounting_unit) if time_accounting_unit.present?
    Setting.set('time_accounting_unit_custom', time_accounting_unit_custom) if time_accounting_unit == 'custom'

    active_type && inactive_type

    true
  end

  before do
    visit "#ticket/zoom/#{ticket.id}"

    find(:richtext).send_keys article_body
    click_button 'Update'
  end

  describe 'time units' do
    shared_examples 'accounting time' do |time_accounting_unit = '', display_unit = nil|
      let(:time_accounting_unit)        { time_accounting_unit }
      let(:time_accounting_unit_custom) { display_unit }

      it 'accounts time with no unit', if: !display_unit do
        in_modal do
          expect(page).to have_text('Time Accounting')
          expect(page).to have_no_css('.time-accounting-display-unit')

          fill_in 'time_unit', with: time_unit

          click_button 'Account Time'
        end

        expect(find('.accounted-time-value')).to have_text(time_unit, exact: true)
      end

      it "accounts time in #{display_unit}", if: display_unit do
        in_modal do
          expect(page).to have_text('Time Accounting')
          expect(page).to have_text(display_unit)

          fill_in 'time_unit', with: time_unit

          click_button 'Account Time'
        end

        expect(find('.accounted-time-value')).to have_text("#{time_unit} #{display_unit}", exact: true)
      end
    end

    context 'without a unit' do
      it_behaves_like 'accounting time'
    end

    context 'with a pre-defined unit' do
      it_behaves_like 'accounting time', 'minute', 'minute(s)'
    end

    context 'with a custom unit' do
      it_behaves_like 'accounting time', 'custom', 'person day(s)'
    end
  end

  describe 'time input' do
    it 'handles user hiding the time accounting modal' do
      in_modal do
        # click on background to close modal
        execute_script 'document.elementFromPoint(300, 100).click();'
      end

      # try to submit again
      click_button 'Update'

      in_modal do
        fill_in 'time_unit', with: '123'

        click_button 'Account Time'
      end

      expect(find('.accounted-time-value')).to have_text('123.0', exact: true)
    end

    it 'allows to input time with a comma and saves with a dot instead' do
      in_modal do
        fill_in 'time_unit', with: '4,6'

        click_button 'Account Time'
      end

      expect(find('.accounted-time-value')).to have_text('4.6', exact: true)
    end

    it 'allows to input time with a trailing space' do
      in_modal do
        fill_in 'time_unit', with: '4 '

        click_button 'Account Time'
      end

      expect(find('.accounted-time-value')).to have_text('4.0', exact: true)
    end

    it 'does not allow to input time with letters' do
      in_modal do
        fill_in 'time_unit', with: '4abc'

        click_button 'Account Time'

        expect(page).to have_css('.input.has-error [name=time_unit]')
      end
    end
  end

  describe 'activity type' do
    context 'when time_accounting_types is disabled' do
      it 'does not show types dropdown' do
        in_modal do
          expect(page).to have_no_text %r{Activity Type}i
        end
      end
    end

    context 'when time_accounting_types is enabled' do
      let(:time_accounting_types) { true }

      it 'shows types dropdown' do
        in_modal do
          expect(page).to have_select 'Activity Type', options: ['-', active_type.name]
        end
      end
    end
  end
end
