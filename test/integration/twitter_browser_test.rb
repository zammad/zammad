# encoding: utf-8
require 'browser_test_helper'

class TwitterBrowserTest < TestCase
  def test_add_config

    # app config
    if !ENV['TWITTER_BT_CONSUMER_KEY']
      raise "ERROR: Need TWITTER_BT_CONSUMER_KEY - hint TWITTER_BT_CONSUMER_KEY='1234'"
    end
    consumer_key = ENV['TWITTER_BT_CONSUMER_KEY']
    if !ENV['TWITTER_BT_CONSUMER_SECRET']
      raise "ERROR: Need TWITTER_BT_CONSUMER_SECRET - hint TWITTER_BT_CONSUMER_SECRET='1234'"
    end
    consumer_secret = ENV['TWITTER_BT_CONSUMER_SECRET']

    if !ENV['TWITTER_BT_USER_LOGIN']
      raise "ERROR: Need TWITTER_BT_USER_LOGIN - hint TWITTER_BT_USER_LOGIN='1234'"
    end
    twitter_user_login = ENV['TWITTER_BT_USER_LOGIN']

    if !ENV['TWITTER_BT_USER_PW']
      raise "ERROR: Need TWITTER_BT_USER_PW - hint TWITTER_BT_USER_PW='1234'"
    end
    twitter_user_pw = ENV['TWITTER_BT_USER_PW']

    if !ENV['TWITTER_BT_CUSTOMER_TOKEN']
      raise "ERROR: Need TWITTER_BT_CUSTOMER_TOKEN - hint TWITTER_BT_CUSTOMER_TOKEN='1234'"
    end
    twitter_customer_token = ENV['TWITTER_BT_CUSTOMER_TOKEN']

    if !ENV['TWITTER_BT_CUSTOMER_TOKEN_SECRET']
      raise "ERROR: Need TWITTER_BT_CUSTOMER_TOKEN_SECRET - hint TWITTER_BT_CUSTOMER_TOKEN_SECRET='1234'"
    end
    twitter_customer_token_secret = ENV['TWITTER_BT_CUSTOMER_TOKEN_SECRET']

    hash = "#sweet#{hash_gen}"

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
      auto_wizard: true,
    )
    tasks_close_all()

    click(css: 'a[href="#manage"]')
    click(css: '.content.active a[href="#channels/twitter"]')
    click(css: '.content.active .js-configApp')
    sleep 2
    set(
      css: '.content.active .modal [name=consumer_key]',
      value: consumer_key,
    )
    set(
      css: '.content.active .modal [name=consumer_secret]',
      value: 'wrong',
    )
    click(css: '.content.active .modal .js-submit')

    watch_for(
      css: '.content.active .modal .alert',
      value: 'Authorization Required',
    )

    set(
      css: '.content.active .modal [name=consumer_secret]',
      value: consumer_secret,
    )
    click(css: '.content.active .modal .js-submit')

    watch_for_disappear(
      css: '.content.active .modal .alert',
      value: 'Authorization Required',
    )

    watch_for(
      css: '.content.active .js-new',
      value: 'add account',
    )

    click(css: '.content.active .js-configApp')

    set(
      css: '.content.active .modal [name=consumer_secret]',
      value: 'wrong',
    )
    click(css: '.content.active .modal .js-submit')

    watch_for(
      css: '.content.active .modal .alert',
      value: 'Authorization Required',
    )

    set(
      css: '.content.active .modal [name=consumer_secret]',
      value: consumer_secret,
    )
    click(css: '.content.active .modal .js-submit')

    watch_for_disappear(
      css: '.content.active .modal .alert',
      value: 'Authorization Required',
    )

    watch_for(
      css: '.content.active .js-new',
      value: 'add account',
    )

    click(css: '.content.active .js-new')

    sleep 10

    set(
      css: '#username_or_email',
      value: twitter_user_login,
      no_click: true, # <label> other element would receive the click
    )
    set(
      css: '#password',
      value: twitter_user_pw,
      no_click: true, # <label> other element would receive the click
    )
    click(css: '#allow')

    #watch_for(
    #  css: '.notice.callback',
    #  value: 'Redirecting you back to the application',
    #)

    watch_for(
      css: '.content.active .modal',
      value: 'Search Terms',
    )

    # add hash tag to search
    click(css: '.content.active .modal .js-searchTermAdd')
    set(css: '.content.active .modal [name="search::term"]', value: hash)
    select(css: '.content.active .modal [name="search::group_id"]', value: 'Users')
    click(css: '.content.active .modal .js-submit')
    modal_disappear

    watch_for(
      css: '.content.active',
      value: 'Bob Mutschler',
    )
    watch_for(
      css: '.content.active',
      value: "@#{twitter_user_login}",
    )
    exists(
      css: '.content.active .main .action:nth-child(1)'
    )
    exists_not(
      css: '.content.active .main .action:nth-child(2)'
    )

    # add account again
    click(css: '.content.active .js-new')

    sleep 10

    click(css: '#allow')

    watch_for(
      css: '.content.active .modal',
      value: 'Search Terms',
    )

    click(css: '.content.active .modal .js-close')

    watch_for(
      css: '.content.active',
      value: 'Bob Mutschler',
    )
    watch_for(
      css: '.content.active',
      value: "@#{twitter_user_login}",
    )
    exists(
      css: '.content.active .main .action:nth-child(1)'
    )
    exists_not(
      css: '.content.active .main .action:nth-child(2)'
    )

    # wait till new streaming of channel is active
    sleep 80

    # start tweet from customer
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = twitter_customer_token
      config.access_token_secret = twitter_customer_token_secret
    end

    text  = "Today #{rand_word}... #{hash} #{hash_gen}"
    tweet = client.update(
      text,
    )

    # watch till tweet is in app
    click(text: 'Overviews')

    # enable full overviews
    execute(
      js: '$(".content.active .sidebar").css("display", "block")',
    )

    click(text: 'Unassigned & Open')

    watch_for(
      css: '.content.active',
      value: hash,
      timeout: 36,
    )

    ticket_open_by_title(
      title: hash,
    )

    # reply via app
    click(css: '.content.active [data-type="twitterStatusReply"]')

    ticket_update(
      data: {
        body: '@dzucker6 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890',
      },
      do_not_submit: true,
    )
    click(
      css: '.content.active .js-submit',
    )
    sleep 10
    click(
      css: '.content.active .js-reset',
    )
    sleep 2

    match_not(
      css: '.content.active',
      value: '1234567890',
    )

    click(css: '.content.active [data-type="twitterStatusReply"]')
    sleep 2

    re_hash = "#{hash}re#{rand(99_999)}"

    ticket_update(
      data: {
        body: "@dzucker6 #{rand_word} reply #{re_hash} #{rand(999_999)}",
      },
    )
    sleep 20

    match(
      css: '.content.active .ticket-article',
      value: re_hash,
    )

    # watch till tweet reached customer
    sleep 10
    text = nil
    client.search(re_hash, result_type: 'mixed').collect { |local_tweet|
      text = local_tweet.text
    }
    assert(text)

  end

  def hash_gen
    (0...10).map { ('a'..'z').to_a[rand(26)] }.join + rand(999).to_s
  end

  def rand_word
    words = [
      'dog',
      'cat',
      'house',
      'home',
      'yesterday',
      'tomorrow',
      'new york',
      'berlin',
      'coffee script',
      'java script',
      'bob smith',
      'be open',
      'really nice',
      'stay tuned',
      'be a good boy',
      'invent new things',
    ]
    words[rand(words.length)]
  end

end
