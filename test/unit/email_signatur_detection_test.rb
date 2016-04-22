# encoding: utf-8
require 'test_helper'

class EmailSignaturDetectionTest < ActiveSupport::TestCase

  test 'test case I - sender a' do

    # fixtures of sender a
    fixture_files = {
      'email_signature_detection/client_a_1.txt' => { line: 10 },
      'email_signature_detection/client_a_2.txt' => { line: 20 },
      'email_signature_detection/client_a_3.txt' => { line: 6 },
    }

    fixture_files_string_list = []

    fixture_files.keys.each do |filepath|

      file = File.new("#{Rails.root}/test/fixtures/#{filepath}", 'r')

      file_content = file.read
      fixture_files[filepath][:content] = file_content
      fixture_files_string_list.push(file_content)
    end

    signature = SignatureDetection.find_signature(fixture_files_string_list)
    expected_signature = "\nMit freundlichen Grüßen\n\nBob Smith\nBerechtigungen und dez. Department\n________________________________\n\nMusik AG\nBerechtigungen und dez. Department (ITPBM)\nKastanien 2\n12345 Hornhausen\nTel.: +49 911 6760\nFax: +49 911 85 6760\nMobil: +49 173 911\nE-Mail: Bob.Smith@music.com\nhttp://www.music.com\n\nMusik AG | Kastanien 2 | 12345 Hornhausen\nSitz der AG: Hornhausen, HRB xxxxx | USt.-ID: DE 111222333444\nVorstand: Marc Smith, Weber Huber\nAufsichtsrat: Max Mix (Vors.)"
    assert_equal(expected_signature, signature)

    fixture_files.keys.each do |filepath|
      expected_signature_position = fixture_files[filepath][:line]

      assert_equal(expected_signature_position, SignatureDetection.find_signature_line(signature, fixture_files[filepath][:content]))
    end
  end

  test 'test case II - sender b' do

    fixture_files = {
      'email_signature_detection/client_b_1.txt' => { line: 26 },
      'email_signature_detection/client_b_2.txt' => { line: 4 },
      'email_signature_detection/client_b_3.txt' => { line: 6 },
    }

    fixture_files_string_list = []

    fixture_files.keys.each do |filepath|

      file = File.new("#{Rails.root}/test/fixtures/#{filepath}", 'r')

      file_content = file.read
      fixture_files[filepath][:content] = file_content
      fixture_files_string_list.push(file_content)
    end

    signature = SignatureDetection.find_signature(fixture_files_string_list)
    expected_signature = "\nFreundliche Grüße\n\nGünter Lässig\nLokale Daten\n\nMusic GmbH\nBaustraße 123, 12345 Max City\nTelefon 0123 5432114\nTelefax 0123 5432139\nE-Mail Günter.Lässig@example.com<mailto:Günter.Lässig@example.com>\n\nExample. Zusammen für eine bessere Welt.\n[cid:image001.png@01CE92A6.EC495B60]<http://www.example.com/>\n\n[cid:image002.png@01CE92A6.EC495B60]<http://www.facebook.com/example.com>\n\n[cid:image003.png@01CE92A6.EC495B60]<http://twitter.com/example>\n\n[cid:image004.png@01CE92A6.EC495B60]<https://www.xing.com/companies/example/neu-example>\n\n[cid:image005.jpg@01CE92A6.EC495B60]<http://www.youtube.com/example>\n\n[cid:image006.png@01CE92A6.EC495B60]<http://www.example.com/no_cache/privatkunden/aktuelles/news-presse/newsletter.html>\n\nSitz der Gesellschaft: Max City, Amtsgericht Max City HRB Nr. 1234\nGeschäftsführer: Bob Smith\nVorsitzender des Aufsichtsrats: Alex Marx"
    assert_equal(expected_signature, signature)

    fixture_files.keys.each do |filepath|
      expected_signature_position = fixture_files[filepath][:line]

      assert_equal(expected_signature_position, SignatureDetection.find_signature_line(signature, fixture_files[filepath][:content]))
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
    Delayed::Worker.new.work_off

    # process email II
    file = File.open("#{Rails.root}/test/fixtures/email_signature_detection/client_a_2.txt", 'rb')
    raw_email = raw_email_header + file.read
    ticket2, article2, user2, mail = Channel::EmailParser.new.process({}, raw_email)
    assert(ticket2)
    assert(article2)
    Delayed::Worker.new.work_off

    # check if user2 has a signature_detection value
    user2 = User.find(user2.id)
    assert(user2.preferences[:signature_detection])

    # process email III
    file = File.open("#{Rails.root}/test/fixtures/email_signature_detection/client_a_3.txt", 'rb')
    raw_email = raw_email_header + file.read
    ticket3, article3, user3, mail = Channel::EmailParser.new.process({}, raw_email)
    assert(ticket3)
    assert(article3)
    Delayed::Worker.new.work_off

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
