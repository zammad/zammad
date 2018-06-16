
require 'test_helper'

class EmailSignatureDetectionTest < ActiveSupport::TestCase

  test 'test case 1 - sender a' do
    message_files = [Rails.root.join('test', 'data', 'email_signature_detection', 'client_a_1.txt'),
                     Rails.root.join('test', 'data', 'email_signature_detection', 'client_a_2.txt'),
                     Rails.root.join('test', 'data', 'email_signature_detection', 'client_a_3.txt')]
    signature_lines = [10, 20, 6]

    messages = message_files.zip(signature_lines).map do |f, l|
      { content: File.read(Rails.root.join('test', 'data', f)),
        content_type: 'text/plain',
        line: l }
    end

    signature = SignatureDetection.find_signature(messages)
    expected_signature = "\nMit freundlichen Grüßen\n\nBob Smith\nBerechtigungen und dez. Department\n________________________________\n\nMusik AG\nBerechtigungen und dez. Department (ITPBM)\nKastanien 2"
    assert_equal(expected_signature, signature)

    messages.each do |m|
      assert_equal(m[:line], SignatureDetection.find_signature_line(signature, m[:content], m[:content_type]))
    end
  end

  test 'test case 2 - sender b' do
    message_files = [Rails.root.join('test', 'data', 'email_signature_detection', 'client_b_1.txt'),
                     Rails.root.join('test', 'data', 'email_signature_detection', 'client_b_2.txt'),
                     Rails.root.join('test', 'data', 'email_signature_detection', 'client_b_3.txt')]
    signature_lines = [26, 4, 6]

    messages = message_files.zip(signature_lines).map do |f, l|
      { content: File.read(Rails.root.join('test', 'data', f)),
        content_type: 'text/plain',
        line: l }
    end

    signature = SignatureDetection.find_signature(messages)
    expected_signature = "\nFreundliche Grüße\n\nGünter Lässig\nLokale Daten\n\nMusic GmbH\nBaustraße 123, 12345 Max City\nTelefon 0123 5432114\nTelefax 0123 5432139"
    assert_equal(expected_signature, signature)

    messages.each do |m|
      assert_equal(m[:line], SignatureDetection.find_signature_line(signature, m[:content], m[:content_type]))
    end
  end

  test 'test case 3 - just tests' do
    signature = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~\nBob Smith\nABC Organisation\n\nEXAMPLE IT-Service GmbH\nDorten 5 F&E\n12345 Da / Germany\nPhone: +49 (0) 1234 567 890 / +49 (0) 1234 567 891\nFax:     +49 (0) 1234 567 892"
    message = File.read(Rails.root.join('test', 'data', 'email_signature_detection', 'example1.html'))
    signature_line = SignatureDetection.find_signature_line(signature, message, 'text/html')
    assert_equal(11, signature_line)
  end

  test 'test case 4 - sender c' do
    message_files = [Rails.root.join('test', 'data', 'email_signature_detection', 'client_c_1.html'),
                     Rails.root.join('test', 'data', 'email_signature_detection', 'client_c_2.html'),
                     Rails.root.join('test', 'data', 'email_signature_detection', 'client_c_3.html')]
    signature_lines = [8, 29, 6]

    messages = message_files.zip(signature_lines).map do |f, l|
      { content: File.read(Rails.root.join('test', 'data', f)),
        content_type: 'text/html',
        line: l }
    end

    signature = SignatureDetection.find_signature(messages)
    expected_signature = "\nChristianSmith\nTechnik\n\nTel: +49 12 34 56 78 441\nFax: +49 12 34 56 78 499\nEmail: Christian.Smith@example.com\nWeb: www.example.com\nABC KFZ- und Flugzeug B.V. & Co. KG\nHauptverwaltung"
    assert_equal(expected_signature, signature)

    messages.each do |m|
      assert_equal(m[:line], SignatureDetection.find_signature_line(signature, m[:content], m[:content_type]))
    end
  end

  test 'test case III - sender a - full cycle' do
    header = "From: Bob.Smith@music.com\nTo: test@zammad.org\nSubject: test\n\n"

    # process email I
    body = File.binread(Rails.root.join('test', 'data', 'email_signature_detection', 'client_a_1.txt'))
    raw_email = header + body
    ticket1, article1, user1, mail = Channel::EmailParser.new.process({}, raw_email)
    assert(ticket1)
    assert(article1)
    Scheduler.worker(true)

    # process email II
    body = File.binread(Rails.root.join('test', 'data', 'email_signature_detection', 'client_a_2.txt'))
    raw_email = header + body
    ticket2, article2, user2, mail = Channel::EmailParser.new.process({}, raw_email)
    assert(ticket2)
    assert(article2)
    Scheduler.worker(true)

    # check if user2 has a signature_detection value
    user2 = User.find(user2.id)
    assert(user2.preferences[:signature_detection])

    # process email III
    body = File.binread(Rails.root.join('test', 'data', 'email_signature_detection', 'client_a_3.txt'))
    raw_email = header + body
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
