# encoding: utf-8
require 'test_helper'

class EmailSignaturDetectionTest < ActiveSupport::TestCase

  test 'test case I - sender a' do

    # fixtures of sender a
    fixture_files = [
      'email_signature_detection/client_a_1.txt',
      'email_signature_detection/client_a_2.txt',
      'email_signature_detection/client_a_3.txt',
    ]

    # detect signature
    match_structure = ''

    # tests
    # 'email_signature_detection/client_a_1.txt'
    result_should = {
      line: 9
    }

    # 'email_signature_detection/client_a_2.txt'
    result_should = {
      line: 7
    }

    # 'email_signature_detection/client_a_3.txt'
    result_should = {
      line: 7
    }
    assert(true)
  end

  test 'test case II - sender b' do

    # fixtures of sender a
    fixture_files = [
      'email_signature_detection/client_b_1.txt',
      'email_signature_detection/client_b_2.txt',
      'email_signature_detection/client_b_3.txt',
    ]

    # detect signature
    match_structure = ''

    # tests
    # 'email_signature_detection/client_b_1.txt'
    result_should = {
      line: 27
    }

    # 'email_signature_detection/client_b_2.txt'
    result_should = {
      line: 5
    }

    # 'email_signature_detection/client_b_3.txt'
    result_should = {
      line: 7
    }
    assert(true)
  end

end
