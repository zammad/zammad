require 'rails_helper'

RSpec.describe 'QUnit', type: :system, authenticated: false, set_up: true, websocket: false do

  def q_unit_tests(test_name)

    visit "/tests_#{test_name}"

    yield if block_given?

    expect(page).to have_css('.result', text: 'Tests completed')
    expect(page).to have_css('.result .failed', text: '0')
  end

  def async_q_unit_tests(*args)
    q_unit_tests(*args) do
      wait(10, interval: 4).until_constant do
        find('.total').text
      end
    end
  end

  scenario 'Core' do
    async_q_unit_tests('core')
  end

  context 'UI' do

    scenario 'Base' do
      q_unit_tests('ui')
    end

    scenario 'Model' do
      async_q_unit_tests('model')
    end

    scenario 'Model binding' do
      q_unit_tests('model_binding')
    end

    scenario 'Model UI' do

      if !ENV['CI']
        skip("Can't run locally because of dependence of special Timezone")
      end

      q_unit_tests('model_ui')
    end

    scenario 'Ticket selector' do
      q_unit_tests('ticket_selector')
    end
  end

  context 'Form' do

    scenario 'Base' do
      async_q_unit_tests('form')
    end

    scenario 'Trim' do
      q_unit_tests('form_trim')
    end

    scenario 'Find' do
      q_unit_tests('form_find')
    end

    scenario 'Timer' do
      q_unit_tests('form_timer')
    end

    scenario 'Extended' do
      q_unit_tests('form_extended')
    end

    scenario 'Searchable select' do
      q_unit_tests('form_searchable_select')
    end

    scenario 'Tree select' do
      q_unit_tests('form_tree_select')
    end

    scenario 'Column select' do
      q_unit_tests('form_column_select')
    end

    it 'Ticket perform action' do
      q_unit_tests('form_ticket_perform_action')
    end

    it 'Validation' do
      q_unit_tests('form_validation')
    end
  end

  context 'Table' do

    scenario 'Base' do
      q_unit_tests('table')
    end

    scenario 'Extended' do
      q_unit_tests('table_extended')
    end

    scenario 'HTML utils' do
      q_unit_tests('html_utils')
    end

    scenario 'Taskbar' do
      q_unit_tests('taskbar')
    end
  end
end
