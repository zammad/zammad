# encoding: utf-8
# rubocop:disable all
require 'test_helper'

class EmailRegexTest < ActiveSupport::TestCase

  test 'should be able to detect valid/invalid the regex filter' do
    # check with exact email, check_mode = true
    sender = 'foobar@foo.bar'
    from = 'foobar@foo.bar'
    regex = EmailRegex.match(from, sender, true, true)
    
    assert_equal(true, regex)

    # check with exact email
    sender = 'foobar@foo.bar'
    from = 'foobar@foo.bar'
    regex = EmailRegex.match(from, sender, true, false)
    
    assert_equal(true, regex)

    # check with regex: filter check_mode = true
    sender = 'regex:foobar@.*'
    from = 'foobar@foo.bar'
    regex = EmailRegex.match(from, sender, true, true)

    assert_equal(true, regex)

    # check with regex: filter
    sender = 'regex:foobar@.*'
    from = 'foobar@foo.bar'
    regex = EmailRegex.match(from, sender, true, false)

    assert_equal(true, regex)

    # check regex with regex: filter
    sender = 'regex:??'
    from = 'foobar@foo.bar'
    regex = EmailRegex.match(from, sender, true, false)
   
    assert_equal(false, regex)

    # check regex with raise error (check_mode = true)
    assert_raises("Can't use regex '??' on 'foobar@foo.bar'") {
      sender = 'regex:??'
      from = 'foobar@foo.bar'
      regex = EmailRegex.match(from, sender, true, true)
    }    

    sender = 'regex:[]'
    from = 'foobar@foo.bar'
    regex = EmailRegex.match(from, sender, true, false)
    
    assert_equal(false, regex)

    # check regex with raise error, (check_mode = true)
    assert_raises("Can't use regex '[]' on 'foobar@foo.bar'") {
      sender = 'regex:[]'
      from = 'foobar@foo.bar'
      regex = EmailRegex.match(from, sender, true, true)
    }

    # check regex with empty field
    sender = '{}'
    from = 'foobar@foo.bar'
    regex = EmailRegex.match(from, sender, true, false)
    assert_equal(false, regex)

    # check regex with empty field and raise error (check_mode = true)
    sender = '{}'
    from = 'foobar@foo.bar'
    regex = EmailRegex.match(from, sender, true, true)
    assert_equal(false, regex)

    # check regex with empty field
    sender = ''
    from = 'foobar@foo.bar'
    regex = EmailRegex.match(from, sender, true, false)
    assert_equal(true, regex)

    # check regex with empty field
    sender = ''
    from = 'foobar@foo.bar'
    regex = EmailRegex.match(from, sender, true, true)
    assert_equal(true, regex)

    # check regex with regex: wildcard
    sender = 'regex:*'
    from = 'foobar@foo.bar'
    regex = EmailRegex.match(from, sender, true, false)

    assert_equal(false, regex)

    # check regex with regex: wildcard and raise error (check_mode = true)
    assert_raises("Can't use regex '*' on 'foobar@foo.bar'") {
      sender = 'regex:*'
      from = 'foobar@foo.bar'
      regex = EmailRegex.match(from, sender, true, true)
    }

    # check email with wildcard
    sender = '*'
    from = 'foobar@foo.bar'
    regex = EmailRegex.match(from, sender, true, false)

    assert_equal(true, regex) 

    # check email with wildcard (check_mode = true)
    sender = '*'
    from = 'foobar@foo.bar'
    regex = EmailRegex.match(from, sender, true, true)

    assert_equal(true, regex) 

    # check email with a different sender
    sender = 'regex:nagios@.*'
    from = 'foobar@foo.bar'
    regex = EmailRegex.match(from, sender, true, false)
    assert_equal(false, regex)

    # check email with a different sender with checkmode = true
    sender = 'regex:nagios@.*'
    from = 'foobar@foo.bar'
    regex = EmailRegex.match(from, sender, true, true)
    assert_equal(false, regex)
  end
end
