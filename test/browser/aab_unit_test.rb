require 'browser_test_helper'

class AAbUnitTest < TestCase
  def test_core
    @browser = browser_instance
    location(url: browser_url + '/tests_core')
    sleep 5
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 4,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )
  end

  def test_ui
    @browser = browser_instance
    location(url: browser_url + '/tests_session')
    sleep 5
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_ui')
    sleep 5
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_model')
    sleep 5
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 3,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_model_binding')
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_model_ui')
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_ticket_selector')
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )
  end

  def test_form
    @browser = browser_instance
    location(url: browser_url + '/tests_form')
    sleep 5
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 2,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_trim')
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_find')
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_timer')
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_extended')
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_searchable_select')
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_ticket_perform_action')
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_tree_select')
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_column_select')
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_validation')
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )
  end

  def test_table
    @browser = browser_instance
    location(url: browser_url + '/tests_table')
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_table_extended')
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_html_utils')
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 8,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_taskbar')
    sleep 5
    watch_for(
      css:     '.result',
      value:   'Tests completed',
      timeout: 3,
    )
    match(
      css:   '.result .failed',
      value: '0',
    )
  end
end
