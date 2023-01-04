# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Facebook, current_user_id: 1, required_envs: %w[FACEBOOK_ADMIN_USER_ID FACEBOOK_ADMIN_FIRSTNAME FACEBOOK_ADMIN_LASTNAME FACEBOOK_ADMIN_ACCESS_TOKEN FACEBOOK_PAGE_1_ACCCESS_TOKEN FACEBOOK_PAGE_1_ID FACEBOOK_PAGE_1_NAME FACEBOOK_PAGE_1_POST_ID FACEBOOK_PAGE_1_POST_MESSAGE FACEBOOK_PAGE_1_POST_COMMENT_ID FACEBOOK_PAGE_2_ACCCESS_TOKEN FACEBOOK_PAGE_2_ID FACEBOOK_PAGE_2_NAME FACEBOOK_CUSTOMER_ID FACEBOOK_CUSTOMER_FIRSTNAME FACEBOOK_CUSTOMER_LASTNAME], use_vcr: true do

  before do
    travel_to '2021-02-13 13:37 +0100'
  end

  let(:page_access_token)  { ENV['FACEBOOK_PAGE_1_ACCCESS_TOKEN'] }
  let(:page_client)        { described_class.new page_access_token }
  let(:admin_access_token) { ENV['FACEBOOK_ADMIN_ACCESS_TOKEN'] }
  let(:admin_client)       { described_class.new admin_access_token }

  let(:post) do
    page_client
      .client
      .get_connection('me', 'feed', fields: 'id,from,to,message,created_time,permalink_url,comments{id,from,to,message,created_time}')
      .first
  end

  let(:page) { admin_client.pages.first }

  describe '#connect' do
    it 'works as expected' do
      expect(page_client.client.get_object('me')['name']).to eq ENV['FACEBOOK_PAGE_1_NAME']
    end
  end

  describe '#pages' do
    it 'works as expected' do
      expect(admin_client.pages.pluck(:name)).to eq [ENV['FACEBOOK_PAGE_1_NAME'], ENV['FACEBOOK_PAGE_2_NAME']]
    end
  end

  describe '#current_user' do
    it 'works for user' do
      expect(admin_client.current_user['name']).to eq "#{ENV['FACEBOOK_ADMIN_FIRSTNAME']} #{ENV['FACEBOOK_ADMIN_LASTNAME']}"
    end

    it 'works for page' do
      expect(page_client.current_user['name']).to eq ENV['FACEBOOK_PAGE_1_NAME']
    end
  end

  describe '#to_user' do

    let(:posts) { page_client.client.get_connection('me', 'feed', fields: 'id,from,to,message,created_time,permalink_url,comments{id,from,to,message,created_time}') }
    let(:user)  { page_client.to_user(posts.first) }

    it 'works as expected' do
      expect(user).to have_attributes(
        firstname: ENV['FACEBOOK_CUSTOMER_FIRSTNAME'],
        lastname:  ENV['FACEBOOK_CUSTOMER_LASTNAME']
      )
    end
  end

  describe '#to_ticket' do
    it 'works as expected' do
      ticket = page_client.to_ticket(post, Group.first.id, Channel.first, page)

      expect(ticket.title).to eq ENV['FACEBOOK_PAGE_1_POST_MESSAGE']
    end
  end

  describe '#to_article' do
    it 'works as expected' do
      ticket   = page_client.to_ticket(post, Group.first.id, Channel.first, page)
      articles = page_client.to_article(post, ticket, page)

      expect(articles.first[:body]).to eq ENV['FACEBOOK_PAGE_1_POST_MESSAGE']
    end
  end

  describe '#to_group' do
    let(:ticket) { page_client.to_group(post, Group.first.id, Channel.first, page) }

    it 'parses title correctly' do
      expect(ticket.title).to eq ENV['FACEBOOK_PAGE_1_POST_MESSAGE']
    end

    it 'parses body correctly', current_user_id: 1 do
      expect(ticket.articles.first.body).to eq ENV['FACEBOOK_PAGE_1_POST_MESSAGE']
    end
  end

  describe '#from_article' do
    let(:ticket)  { page_client.to_group(post, Group.first.id, Channel.first, page) }
    let(:article) { create(:ticket_article, ticket: ticket, type_name: 'facebook feed comment', in_reply_to: ticket.articles.last.message_id) }
    let(:response) do
      page_client.from_article(
        type:        article.type.name,
        to:          article.to,
        body:        article.body,
        in_reply_to: article.in_reply_to,
      )
    end

    it 'works as expected' do
      expect(response['id']).to be_present
    end
  end
end
