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

  it 'Core' do
    async_q_unit_tests('core')
  end

  context 'UI' do

    it 'Base' do
      q_unit_tests('ui')
    end

    it 'Local storage' do
      q_unit_tests('local_storage')
    end

    it 'Model' do
      async_q_unit_tests('model')
    end

    it 'Model binding' do
      q_unit_tests('model_binding')
    end

    it 'Model UI' do

      if !ENV['CI']
        skip("Can't run locally because of dependence of special Timezone")
      end

      q_unit_tests('model_ui')
    end

    it 'Model Ticket' do
      q_unit_tests('model_ticket')
    end

    it 'Ticket selector' do
      q_unit_tests('ticket_selector')
    end
  end

  context 'Form' do

    it 'Base' do
      async_q_unit_tests('form')
    end

    it 'Trim' do
      q_unit_tests('form_trim')
    end

    it 'Find' do
      q_unit_tests('form_find')
    end

    it 'Timer' do
      q_unit_tests('form_timer')
    end

    it 'Extended' do
      q_unit_tests('form_extended')
    end

    it 'Searchable select' do
      q_unit_tests('form_searchable_select')
    end

    it 'Tree select' do
      q_unit_tests('form_tree_select')
    end

    it 'Column select' do
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

    it 'Base' do
      q_unit_tests('table')
    end

    it 'Extended' do
      q_unit_tests('table_extended')
    end

    it 'HTML utils' do
      q_unit_tests('html_utils')
    end

    it 'Taskbar' do
      q_unit_tests('taskbar')
    end
  end
end
