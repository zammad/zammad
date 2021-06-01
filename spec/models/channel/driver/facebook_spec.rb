# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::Facebook, use_vcr: true do

  before do
    VCR.configure do |c|
      %w[
        FACEBOOK_ADMIN_USER_ID
        FACEBOOK_ADMIN_FIRSTNAME
        FACEBOOK_ADMIN_LASTNAME
        FACEBOOK_PAGE_1_ACCCESS_TOKEN
        FACEBOOK_PAGE_1_ID
        FACEBOOK_PAGE_1_NAME
        FACEBOOK_PAGE_1_POST_ID
        FACEBOOK_PAGE_1_POST_COMMENT_ID
        FACEBOOK_PAGE_2_ACCCESS_TOKEN
        FACEBOOK_PAGE_2_ID
        FACEBOOK_PAGE_2_NAME
        FACEBOOK_CUSTOMER_ID
        FACEBOOK_CUSTOMER_FIRSTNAME
        FACEBOOK_CUSTOMER_LASTNAME
      ].each do |env_key|
        c.filter_sensitive_data("<#{env_key}>") { ENV[env_key] }
      end
    end

    travel_to '2021-02-13 13:37 +0100'
  end

  let!(:channel) { create(:facebook_channel) }

  it 'tests full run' do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
    ExternalCredential.create name: :facebook, credentials: { application_id: ENV['FACEBOOK_APPLICATION_ID'], application_secret: ENV['FACEBOOK_APPLICATION_SECRET'] }

    channel.fetch

    ticket = Ticket.last

    ticket_initial_count = ticket.articles.count

    expect(ticket.preferences['channel_fb_object_id']).to be_present

    message_id = "#{ENV['FACEBOOK_PAGE_1_POST_ID']}_#{ENV['FACEBOOK_PAGE_1_POST_COMMENT_ID']}"
    post_article = ticket.articles.find_by(message_id: message_id)

    article = Ticket::Article.find_by(message_id: post_article.message_id)
    ticket = article.ticket
    expect(ticket.state.name).to eq 'new'
    expect(article).to be_present

    customer = ticket.customer
    expect("#{customer.firstname} #{customer.lastname}").to eq "#{ENV['FACEBOOK_CUSTOMER_FIRSTNAME']} #{ENV['FACEBOOK_CUSTOMER_LASTNAME']}"

    outbound_article = Ticket::Article.create(
      ticket_id:     ticket.id,
      body:          "What's your issue Bernd?",
      in_reply_to:   post_article.message_id,
      type:          Ticket::Article::Type.find_by(name: 'facebook feed comment'),
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )

    Scheduler.worker(true)
    expect(ticket.reload.state.name).to eq 'open'

    outbound_article = Ticket::Article.find(outbound_article.id)
    expect(outbound_article).to be_present
    expect(outbound_article.from).to eq ENV['FACEBOOK_PAGE_1_NAME']
    expect(outbound_article.ticket.articles.count).to be ticket_initial_count + 1
  end
end
