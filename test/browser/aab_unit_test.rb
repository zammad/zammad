# encoding: utf-8
require 'browser_test_helper'

class AAbUnitTest < TestCase
  def test_core
    @browser = browser_instance
    location( url: browser_url + '/tests-core' )
    sleep 10
    match(
      css: '.result .failed',
      value: '0',
    )
  end

  def test_ui
    @browser = browser_instance
    location( url: browser_url + '/tests-ui' )
    sleep 8
    match(
      css: '.result .failed',
      value: '0',
    )

    location( url: browser_url + '/tests-model' )
    sleep 8
    match(
      css: '.result .failed',
      value: '0',
    )

    location( url: browser_url + '/tests-model-ui' )
    sleep 8
    match(
      css: '.result .failed',
      value: '0',
    )
  end

  def test_form
    @browser = browser_instance
    location( url: browser_url + '/tests-form' )
    sleep 8
    match(
      css: '.result .failed',
      value: '0',
    )

    location( url: browser_url + '/tests-form-trim' )
    match(
      css: '.result .failed',
      value: '0',
    )

    location( url: browser_url + '/tests-form-extended' )
    sleep 8
    match(
      css: '.result .failed',
      value: '0',
    )

    location( url: browser_url + '/tests-form-validation' )
    sleep 4
    match(
      css: '.result .failed',
      value: '0',
    )
  end

  def test_table
    @browser = browser_instance
    location( url: browser_url + '/tests-table' )
    sleep 4
    match(
      css: '.result .failed',
      value: '0',
    )

    location( url: browser_url + '/tests-html-utils' )
    sleep 4
    match(
      css: '.result .failed',
      value: '0',
    )
  end
end
