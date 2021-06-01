# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

# Regression test for UI bugfix
# https://github.com/zammad/zammad/issues/1990
#
# Ensure that CC field when creating a new ticket is autocompleting user emails

class AgentTicketCreateCcTokenizerTest < TestCase
  def test_tokenizer
    @browser = browser_instance

    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    click(
      css: 'a[href="#ticket/create"]'
    )

    email_out_css = '.content.active li[data-type=email-out]'

    watch_for(
      css: email_out_css
    )

    click(css: email_out_css)

    token_verify('.content.active input[name=cc]', 'test@example.com')
  end
end
