# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
  let(:create_new_article)          { true }

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

    if create_new_article
      find(:richtext).send_keys article_body
      click_on 'Update'

      accounted_time_modal_hook if defined?(accounted_time_modal_hook)
    end
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

          click_on 'Account Time'
        end

        expect(find('.accounted-time-value-row:nth-of-type(1)')).to have_text("Total\n#{time_unit}", exact: true)
      end

      it "accounts time in #{display_unit}", if: display_unit do
        in_modal do
          expect(page).to have_text('Time Accounting')
          expect(page).to have_text(display_unit)

          fill_in 'time_unit', with: time_unit

          click_on 'Account Time'
        end

        expect(find('.accounted-time-value-row:nth-of-type(1)')).to have_text("Total\n#{time_unit}\n#{display_unit}", exact: true)
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
      click_on 'Update'

      in_modal do
        fill_in 'time_unit', with: '123'

        click_on 'Account Time'
      end

      expect(find('.accounted-time-value-row:nth-of-type(1)')).to have_text("Total\n123.0", exact: true)
    end

    it 'allows to input time with a comma and saves with a dot instead' do
      in_modal do
        fill_in 'time_unit', with: '4,6'

        click_on 'Account Time'
      end

      expect(find('.accounted-time-value-row:nth-of-type(1)')).to have_text("Total\n4.6", exact: true)
    end

    it 'allows to input time with a trailing space' do
      in_modal do
        fill_in 'time_unit', with: '4 '

        click_on 'Account Time'
      end

      expect(find('.accounted-time-value-row:nth-of-type(1)')).to have_text("Total\n4.0", exact: true)
    end

    it 'does not allow to input time with letters' do
      in_modal do
        fill_in 'time_unit', with: '4abc'

        click_on 'Account Time'

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

      context 'when more than three types are used', authenticated_as: :authenticate do
        let(:create_new_article)          { false }
        let(:types)                       { create_list(:ticket_time_accounting_type, 4) }

        def authenticate
          Setting.set('time_accounting', true)
          Setting.set('time_accounting_types', time_accounting_types)
          Setting.set('time_accounting_unit', time_accounting_unit) if time_accounting_unit.present?
          Setting.set('time_accounting_unit_custom', time_accounting_unit_custom) if time_accounting_unit == 'custom'

          3.times do
            create(:ticket_time_accounting, ticket: ticket, time_unit: 25, type: types[0])
            create(:ticket_time_accounting, ticket: ticket, time_unit: 50, type: types[1])
            create(:ticket_time_accounting, ticket: ticket, time_unit: 75, type: types[2])
          end

          create(:ticket_time_accounting, ticket: ticket, time_unit: 50, type: types[3])

          true
        end

        it 'shows a table for the top three that is sorted correctly by default and can show all entries', :aggregate_failures do
          expect(page).to have_css('.accounted-time-value-row:nth-of-type(1)', text: "Total\n500.0")
          expect(page).to have_css('.accounted-time-value-row:nth-of-type(2)', text: "#{types[2].name}\n225.0")
          expect(page).to have_css('.accounted-time-value-row:nth-of-type(3)', text: "#{types[1].name}\n150.0")
          expect(page).to have_css('.accounted-time-value-row:nth-of-type(4)', text: "#{types[0].name}\n75.0")

          expect(page).to have_css('.accounted-time-value-container .js-showMoreEntries')

          click('.accounted-time-value-container .js-showMoreEntries')
          expect(page).to have_css('.accounted-time-value-row:nth-of-type(5)', text: "#{types[3].name}\n50.0")
        end
      end

      context 'when new time is accounted or article got deleted', authenticated_as: :authenticate do
        let(:types) { create_list(:ticket_time_accounting_type, 4) }

        let(:accounted_time_modal_hook) do
          in_modal do
            fill_in 'time_unit', with: '123'
            select types[0].name, from: 'Activity Type'

            click_on 'Account Time'
          end
        end

        def authenticate
          Setting.set('time_accounting', true)
          Setting.set('time_accounting_types', time_accounting_types)

          types

          true
        end

        it 'updates the table correctly' do
          expect(page).to have_css('.accounted-time-value-row:nth-of-type(1)', text: "Total\n123.0")
          expect(page).to have_css('.accounted-time-value-row:nth-of-type(2)', text: "#{types[0].name}\n123.0")

          within :active_ticket_article, ticket.reload.articles.last do
            click '.js-ArticleAction[data-type=delete]'
          end

          in_modal do
            click '.js-submit'
          end

          expect(page).to have_css('.accounted-time-value-row:nth-of-type(1)', text: "Total\n0.0")
          expect(page).to have_no_css('.accounted-time-value-row:nth-of-type(2)', text: "#{types[0].name}\n123.0")
        end
      end
    end
  end

  describe "Time accounting: don't list activity types if they are not used #4806", authenticated_as: :authenticate do
    let(:create_new_article) { false }

    context 'with types' do
      let(:type) { create(:ticket_time_accounting_type) }

      def authenticate
        Setting.set('time_accounting', true)
        Setting.set('time_accounting_types', true)
        type
        create(:ticket_time_accounting, ticket: ticket, time_unit: 25)

        true
      end

      it 'does not show the None category if there are no accountings on categories' do
        within '.accounted-time-value-container' do
          expect(page).to have_no_text('None')
        end
      end
    end

    context 'with types disabled' do
      let(:type) { create(:ticket_time_accounting_type) }

      def authenticate
        Setting.set('time_accounting', true)
        Setting.set('time_accounting_types', false)
        create(:ticket_time_accounting, ticket: ticket, time_unit: 25, type: type)

        true
      end

      it 'does not show the Type category if types are disabled' do
        within '.accounted-time-value-container' do
          expect(page).to have_no_text(type.name)
        end
      end
    end
  end
end
