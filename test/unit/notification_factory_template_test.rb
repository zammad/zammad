# encoding: utf-8
require 'test_helper'

class NotificationFactoryTemplateTest < ActiveSupport::TestCase

  # RSpec incoming!
  def described_class
    NotificationFactory::Template
  end

  test 'regular browser html' do

    # ensures https://github.com/zammad/zammad/issues/385
    template_before = '#{<a href="http://ticket.id" title="http://ticket.id" target="_blank">ticket.id</a>}'
    template_after  = '<%= d "ticket.id", true %>'

    result = described_class.new(template_before, true).to_s
    assert_equal(template_after, result)

    template_before = '#{<a href="http://ticket.id" title="http://ticket.id" target="_blank">config.fqdn</a>}'
    template_after  = '<%= d "config.fqdn", true %>'

    result = described_class.new(template_before, true).to_s
    assert_equal(template_after, result)
  end

  test 'spaced browser html' do

    # ensures https://github.com/zammad/zammad/issues/385
    template_before = '#{   <a href="http://ticket.id" title="http://ticket.id" target="_blank">ticket.id  </a>  }'
    template_after  = '<%= d "ticket.id", true %>'

    result = described_class.new(template_before, true).to_s
    assert_equal(template_after, result)
  end

  test 'broken browser html' do

    # ensures https://github.com/zammad/zammad/issues/385
    template_before = '#{<a href="http://ticket.id" title="http://ticket.id" target="_blank">ticket.id  }'
    template_after  = '<%= d "ticket.id", true %>'

    result = described_class.new(template_before, true).to_s
    assert_equal(template_after, result)
  end

  test 'empty tag' do

    template_before = '#{}'
    template_after  = '<%= d "", true %>'

    result = described_class.new(template_before, true).to_s
    assert_equal(template_after, result)
  end

  test 'empty tag with space' do

    template_before = '#{ }'
    template_after  = '<%= d "", false %>'

    result = described_class.new(template_before, false).to_s
    assert_equal(template_after, result)
  end

  test 'translation' do

    template_before = "\#{t('some text')}"
    template_after  = '<%= t "some text", false %>'

    result = described_class.new(template_before, false).to_s
    assert_equal(template_after, result)

    template_before = "\#{t('some \"text\"')}"
    template_after  = '<%= t "some \"text\"", false %>'

    result = described_class.new(template_before, false).to_s
    assert_equal(template_after, result)
  end

end
