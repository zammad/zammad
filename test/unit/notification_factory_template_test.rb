# encoding: utf-8
require 'test_helper'

class NotificationFactoryTemplateTest < ActiveSupport::TestCase

  # RSpec incoming!
  def described_class
    NotificationFactory::Template
  end

  test 'regular browser html' do

    # ensures https://github.com/zammad/zammad/issues/385
    template_before = '<%= d "#{<a href="http://ticket.id" title="http://ticket.id" target="_blank">ticket.id</a>}" %>'
    template_after  = '<%= d "ticket.id" %>'

    result = described_class.new(template_before).to_s
    assert_equal(template_after, result)
  end

  test 'spaced browser html' do

    # ensures https://github.com/zammad/zammad/issues/385
    template_before = '<%= d "#{   <a href="http://ticket.id" title="http://ticket.id" target="_blank">ticket.id  </a>}     " %>'
    template_after  = '<%= d "ticket.id       " %>'

    result = described_class.new(template_before).to_s
    assert_equal(template_after, result)
  end

  test 'broken browser html' do

    # ensures https://github.com/zammad/zammad/issues/385
    template_before = '<%= d "#{<a href="http://ticket.id" title="http://ticket.id" target="_blank">ticket.id  }" %>'
    template_after  = '<%= d "ticket.id  " %>'

    result = described_class.new(template_before).to_s
    assert_equal(template_after, result)
  end
end
