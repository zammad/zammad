# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::Facebook, integration: true, performs_jobs: true, required_envs: %w[FACEBOOK_ADMIN_USER_ID FACEBOOK_ADMIN_FIRSTNAME FACEBOOK_ADMIN_LASTNAME FACEBOOK_PAGE_1_ACCCESS_TOKEN FACEBOOK_PAGE_1_ID FACEBOOK_PAGE_1_NAME FACEBOOK_PAGE_1_POST_ID FACEBOOK_PAGE_1_POST_COMMENT_ID FACEBOOK_PAGE_2_ACCCESS_TOKEN FACEBOOK_PAGE_2_ID FACEBOOK_PAGE_2_NAME FACEBOOK_CUSTOMER_ID FACEBOOK_CUSTOMER_FIRSTNAME], use_vcr: true do

  let(:channel)           { create(:facebook_channel) }
  let(:page_access_token) { ENV['FACEBOOK_PAGE_1_ACCCESS_TOKEN'] }
  let(:page_client)       { Facebook.new page_access_token }

  before do
    # Make sure to use the correct time for the test, otherwise posts are getting too old.
    travel_to(DateTime.parse('2023-05-04 18:00:00 UTC'))
    channel
  end

  # Cleanup of the test comment.
  after do
    page_client
      .client
      .delete_object(Ticket.last.articles.last.message_id)
  end

  # This test requires ENV variables to run
  # Yes, it runs off VCR cassette
  # But it requires following ENV variables to be present:
  #
  # export FACEBOOK_ADMIN_USER_ID=placeholder
  # export FACEBOOK_ADMIN_FIRSTNAME=placeholder
  # export FACEBOOK_ADMIN_LASTNAME=placeholder
  # export FACEBOOK_PAGE_1_ACCCESS_TOKEN=placeholder
  # export FACEBOOK_PAGE_1_ID=placeholder
  # export FACEBOOK_PAGE_1_NAME=placeholder
  # export FACEBOOK_PAGE_1_POST_ID=placeholder
  # export FACEBOOK_PAGE_1_POST_COMMENT_ID=placeholder
  # export FACEBOOK_PAGE_2_ACCCESS_TOKEN=placeholder
  # export FACEBOOK_PAGE_2_ID=placeholder
  # export FACEBOOK_PAGE_2_NAME=placeholder
  # export FACEBOOK_CUSTOMER_ID=placeholder
  # export FACEBOOK_CUSTOMER_FIRSTNAME=placeholder
  #
  it 'tests full run', :aggregate_failures do
    allow(ApplicationHandleInfo).to receive('context=')
    ExternalCredential.create name: :facebook, credentials: { application_id: ENV['FACEBOOK_APPLICATION_ID'], application_secret: ENV['FACEBOOK_APPLICATION_SECRET'] }

    channel.fetch

    ticket = Ticket.last

    ticket_initial_count = ticket.articles.count

    expect(ticket.preferences['channel_fb_object_id']).to be_present

    message_id = "#{ENV['FACEBOOK_PAGE_1_POST_ID']}_#{ENV['FACEBOOK_PAGE_1_POST_COMMENT_ID']}"
    post_article = ticket.articles.find_by(message_id: message_id)

    article = Ticket::Article.find_by(message_id: post_article.message_id)
    ticket = article.ticket
    expect(article).to be_present

    customer = ticket.customer
    expect(customer.fullname).to eq ENV['FACEBOOK_CUSTOMER_FIRSTNAME']

    outbound_article = Ticket::Article.create(
      ticket_id:     ticket.id,
      body:          "What's your issue Nicole?",
      in_reply_to:   post_article.message_id,
      type:          Ticket::Article::Type.find_by(name: 'facebook feed comment'),
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )

    perform_enqueued_jobs

    outbound_article = Ticket::Article.find(outbound_article.id)
    expect(outbound_article).to be_present
    expect(outbound_article.from).to eq ENV['FACEBOOK_PAGE_1_NAME']
    expect(outbound_article.ticket.articles.count).to be ticket_initial_count + 1

    expect(ApplicationHandleInfo).to have_received('context=').with('facebook').at_least(1)
  end
end
