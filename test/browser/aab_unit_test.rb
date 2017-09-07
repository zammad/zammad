# encoding: utf-8
require 'browser_test_helper'

class AAbUnitTest < TestCase
  def test_core
    @browser = browser_instance
    location(url: browser_url + '/tests_core')
    sleep 10
    match(
      css: '.result .failed',
      value: '0',
    )
  end

  def test_ui
    @browser = browser_instance
    location(url: browser_url + '/tests_ui')
    sleep 8
    match(
      css: '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_model')
    sleep 8
    match(
      css: '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_model_ui')
    sleep 8
    match(
      css: '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_ticket_selector')
    sleep 8
    match(
      css: '.result .failed',
      value: '0',
    )
  end

  def test_form
    @browser = browser_instance
    location(url: browser_url + '/tests_form')
    sleep 4
    match(
      css: '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_trim')
    sleep 4
    match(
      css: '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_find')
    sleep 4
    match(
      css: '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_timer')
    sleep 4
    match(
      css: '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_extended')
    sleep 4
    match(
      css: '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_searchable_select')
    sleep 2
    match(
      css: '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_tree_select')
    sleep 2
    match(
      css: '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_column_select')
    sleep 2
    match(
      css: '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_form_validation')
    sleep 4
    match(
      css: '.result .failed',
      value: '0',
    )
  end

  def test_table
    @browser = browser_instance
    location(url: browser_url + '/tests_table')
    sleep 4
    match(
      css: '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_html_utils')
    sleep 4
    match(
      css: '.result .failed',
      value: '0',
    )

    location(url: browser_url + '/tests_taskbar')
    sleep 4
    match(
      css: '.result .failed',
      value: '0',
    )
  end
end
