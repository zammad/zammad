You can create emails this way:

shell $> cat doc/test_mails/test1.eml | rails r 'Channel::MailStdin.new'
