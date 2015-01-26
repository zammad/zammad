# encoding: utf-8
require 'browser_test_helper'

class AAbUnitTest < TestCase
  def test_core
    tests = [
      {
        :name     => 'start',
        :instance => browser_instance,
        :url      => browser_url + '/tests-core',
        :action   => [
          {
            :execute => 'wait',
            :value   => 8,
          },
          {
            :execute      => 'match',
            :css          => '.result .failed',
            :value        => '0',
            :match_result => true,
          },
        ],
      },
    ]
    browser_single_test(tests)
  end
  def test_ui
    tests = [
      {
        :name     => 'start',
        :instance => browser_instance,
        :url      => browser_url + '/tests-ui',
        :action   => [
          {
            :execute => 'wait',
            :value   => 8,
          },
          {
            :execute      => 'match',
            :css          => '.result .failed',
            :value        => '0',
            :match_result => true,
          },
        ],
      },
    ]
    browser_single_test(tests)
  end
  def test_model
    tests = [
      {
        :name     => 'start',
        :instance => browser_instance,
        :url      => browser_url + '/tests-model',
        :action   => [
          {
            :execute => 'wait',
            :value   => 8,
          },
          {
            :execute      => 'match',
            :css          => '.result .failed',
            :value        => '0',
            :match_result => true,
          },
        ],
      },
    ]
    browser_single_test(tests)
  end
  def test_form
    tests = [
      {
        :name     => 'start',
        :instance => browser_instance,
        :url      => browser_url + '/tests-form',
        :action   => [
          {
            :execute => 'wait',
            :value   => 8,
          },
          {
            :execute      => 'match',
            :css          => '.result .failed',
            :value        => '0',
            :match_result => true,
          },
        ],
      },
    ]
    browser_single_test(tests)
  end
  def test_form_extended
    tests = [
      {
        :name     => 'start',
        :instance => browser_instance,
        :url      => browser_url + '/tests-form-extended',
        :action   => [
          {
            :execute => 'wait',
            :value   => 8,
          },
          {
            :execute      => 'match',
            :css          => '.result .failed',
            :value        => '0',
            :match_result => true,
          },
        ],
      },
    ]
    browser_single_test(tests)
  end
  def test_form_validation
    tests = [
      {
        :name     => 'start',
        :instance => browser_instance,
        :url      => browser_url + '/tests-form-validation',
        :action   => [
          {
            :execute => 'wait',
            :value   => 8,
          },
          {
            :execute      => 'match',
            :css          => '.result .failed',
            :value        => '0',
            :match_result => true,
          },
        ],
      },
    ]
    browser_single_test(tests)
  end
  def test_table
    tests = [
      {
        :name     => 'start',
        :instance => browser_instance,
        :url      => browser_url + '/tests-table',
        :action   => [
          {
            :execute => 'wait',
            :value   => 8,
          },
          {
            :execute      => 'match',
            :css          => '.result .failed',
            :value        => '0',
            :match_result => true,
          },
        ],
      },
    ]
    browser_single_test(tests)
  end
  def test_html_utils
    tests = [
      {
        :name     => 'start',
        :instance => browser_instance,
        :url      => browser_url + '/tests-html-utils',
        :action   => [
          {
            :execute => 'wait',
            :value   => 8,
          },
          {
            :execute      => 'match',
            :css          => '.result .failed',
            :value        => '0',
            :match_result => true,
          },
        ],
      },
    ]
    browser_single_test(tests)
  end
end