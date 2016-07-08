# encoding: utf-8
require 'test_helper'

class EmailSignaturDetectionTest < ActiveSupport::TestCase

  test 'test case 1 - sender a' do

    # fixtures of sender a
    fixture_files = {
      'email_signature_detection/client_a_1.txt' => { line: 10, content_type: 'text/plain' },
      'email_signature_detection/client_a_2.txt' => { line: 20, content_type: 'text/plain' },
      'email_signature_detection/client_a_3.txt' => { line: 6, content_type: 'text/plain' },
    }

    fixture_messages = []
    fixture_files.each do |filepath, value|
      value[:content] = File.new("#{Rails.root}/test/fixtures/#{filepath}", 'r').read
      fixture_messages.push value
    end

    signature = SignatureDetection.find_signature(fixture_messages)
    expected_signature = "\nMit freundlichen Grüßen\n\nBob Smith\nBerechtigungen und dez. Department\n________________________________\n\nMusik AG\nBerechtigungen und dez. Department (ITPBM)\nKastanien 2"
    assert_equal(expected_signature, signature)

    fixture_files.each do |_filepath, value|
      assert_equal(value[:line], SignatureDetection.find_signature_line(signature, value[:content], value[:content_type]))
    end
  end

  test 'test case 2 - sender b' do

    fixture_files = {
      'email_signature_detection/client_b_1.txt' => { line: 26, content_type: 'text/plain' },
      'email_signature_detection/client_b_2.txt' => { line: 4, content_type: 'text/plain' },
      'email_signature_detection/client_b_3.txt' => { line: 6, content_type: 'text/plain' },
    }

    fixture_messages = []
    fixture_files.each do |filepath, value|
      value[:content] = File.new("#{Rails.root}/test/fixtures/#{filepath}", 'r').read
      fixture_messages.push value
    end

    signature = SignatureDetection.find_signature(fixture_messages)
    expected_signature = "\nFreundliche Grüße\n\nGünter Lässig\nLokale Daten\n\nMusic GmbH\nBaustraße 123, 12345 Max City\nTelefon 0123 5432114\nTelefax 0123 5432139"
    assert_equal(expected_signature, signature)

    fixture_files.each do |_filepath, value|
      assert_equal(value[:line], SignatureDetection.find_signature_line(signature, value[:content], value[:content_type]))
    end
  end

  test 'test case 3 - just tests' do
    signature = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~\nBob Smith\nABC Organisation\n\nEXAMPLE IT-Service GmbH\nDorten 5 F&E\n12345 Da / Germany\nPhone: +49 (0) 1234 567 890 / +49 (0) 1234 567 891\nFax:     +49 (0) 1234 567 892"
    message = File.new("#{Rails.root}/test/fixtures/email_signature_detection/example1.html", 'r').read
    signature_line = SignatureDetection.find_signature_line(signature, message, 'text/html')
    assert_equal(11, signature_line)
  end

  test 'test case 4 - sender c' do

    fixture_files = {
      'email_signature_detection/client_c_1.html' => { line: 8, content_type: 'text/html' },
      'email_signature_detection/client_c_2.html' => { line: 29, content_type: 'text/html' },
      'email_signature_detection/client_c_3.html' => { line: 9, content_type: 'text/html' },
    }

    fixture_messages = []
    fixture_files.each do |filepath, value|
      value[:content] = File.new("#{Rails.root}/test/fixtures/#{filepath}", 'r').read
      fixture_messages.push value
    end

    signature = SignatureDetection.find_signature(fixture_messages)
    expected_signature = "\nChristianSmith\nTechnik\n\nTel: +49 12 34 56 78 441\nFax: +49 12 34 56 78 499\nEmail: Christian.Smith@example.com\nWeb: www.example.com\nABC KFZ- und Flugzeug B.V. & Co. KG\nHauptverwaltung"
    assert_equal(expected_signature, signature)

    fixture_files.each do |filepath, value|
      assert_equal(value[:line], SignatureDetection.find_signature_line(signature, value[:content], value[:content_type]), filepath)
    end
  end

  test 'test case III - sender a - full cycle' do
    raw_email_header = "From: Bob.Smith@music.com\nTo: test@zammad.org\nSubject: test\n\n"

    # process email I
    file = File.open("#{Rails.root}/test/fixtures/email_signature_detection/client_a_1.txt", 'rb')
    raw_email = raw_email_header + file.read
    ticket1, article1, user1, mail = Channel::EmailParser.new.process({}, raw_email)
    assert(ticket1)
    assert(article1)
    Scheduler.worker(true)

    # process email II
    file = File.open("#{Rails.root}/test/fixtures/email_signature_detection/client_a_2.txt", 'rb')
    raw_email = raw_email_header + file.read
    ticket2, article2, user2, mail = Channel::EmailParser.new.process({}, raw_email)
    assert(ticket2)
    assert(article2)
    Scheduler.worker(true)

    # check if user2 has a signature_detection value
    user2 = User.find(user2.id)
    assert(user2.preferences[:signature_detection])

    # process email III
    file = File.open("#{Rails.root}/test/fixtures/email_signature_detection/client_a_3.txt", 'rb')
    raw_email = raw_email_header + file.read
    ticket3, article3, user3, mail = Channel::EmailParser.new.process({}, raw_email)
    assert(ticket3)
    assert(article3)
    Scheduler.worker(true)

    # check if article3 has a signature_detection value
    article3 = Ticket::Article.find(article3.id)
    assert_equal(article3.preferences[:signature_detection], 6)

    # relbuild all
    SignatureDetection.rebuild_all_articles

    article1 = Ticket::Article.find(article1.id)
    assert_equal(article1.preferences[:signature_detection], 10)

    article2 = Ticket::Article.find(article2.id)
    assert_equal(article2.preferences[:signature_detection], 20)

    article3 = Ticket::Article.find(article3.id)
    assert_equal(article3.preferences[:signature_detection], 6)

  end

end
