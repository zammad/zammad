# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Telegram Webhook Integration', type: :request do

  let!(:token) { 'valid_token' }
  let!(:token2) { 'valid_token2' }
  let!(:bot_id) { 123_456_789 }
  let!(:bot_id2) { 987_654_321 }
  let!(:group_id) { Group.find_by(name: 'Users').id }
  let!(:group_id2) { create(:group).id }

  describe 'request handling' do

    describe 'check_token' do
      it 'invalid token' do
        stub_request(:post, 'https://api.telegram.org/botinvalid_token/getMe')
          .to_return(status: 404, body: '{"ok":false,"error_code":404,"description":"Not Found"}', headers: {})

        expect do
          Telegram.check_token('invalid_token')
        end.to raise_error(Exceptions::UnprocessableEntity)
      end

      it 'valid token' do

        stub_request(:post, "https://api.telegram.org/bot#{token}/getMe")
          .to_return(status: 200, body: "{\"ok\":true,\"result\":{\"id\":#{bot_id},\"first_name\":\"Chrispresso Customer Service\",\"username\":\"ChrispressoBot\"}}", headers: {})

        bot = Telegram.check_token(token)
        expect(bot['id']).to eq(bot_id)
      end
    end

    describe 'create_or_update_channel' do

      it 'via http' do

        Setting.set('http_type', 'http')

        stub_request(:post, "https://api.telegram.org/bot#{token}/getMe")
          .to_return(status: 200, body: "{\"ok\":true,\"result\":{\"id\":#{bot_id},\"first_name\":\"Chrispresso Customer Service\",\"username\":\"ChrispressoBot\"}}", headers: {})

        expect do
          Telegram.create_or_update_channel(token, { group_id: group_id, welcome: 'hi!', goodbye: 'goodbye' })
        end.to raise_error(Exceptions::UnprocessableEntity)
      end

      it 'via https and invalid port' do

        UserInfo.current_user_id = 1
        Setting.set('http_type', 'https')
        Setting.set('fqdn', 'somehost.example.com:12345')

        stub_request(:post, "https://api.telegram.org:443/bot#{token}/getMe")
          .to_return(status: 200, body: "{\"ok\":true,\"result\":{\"id\":#{bot_id},\"first_name\":\"Chrispresso Customer Service\",\"username\":\"ChrispressoBot\"}}", headers: {})
        stub_request(:post, "https://api.telegram.org:443/bot#{token}/setWebhook")
          .with(body: { 'url' => "https://somehost.example.com:12345/api/v1/channels_telegram_webhook/callback_token?bid=#{bot_id}" })
          .to_return(status: 400, body: '{"ok":false,"error_code":400,"description":"Bad Request: bad webhook: Webhook can be set up only on ports 80, 88, 443 or 8443"}', headers: {})

        expect do
          Telegram.create_or_update_channel(token, { group_id: group_id, welcome: 'hi!', goodbye: 'goodbye' })
        end.to raise_error(Exceptions::UnprocessableEntity)
      end

      it 'via https and invalid host' do

        Setting.set('http_type', 'https')
        Setting.set('fqdn', 'somehost.example.com')

        stub_request(:post, "https://api.telegram.org:443/bot#{token}/getMe")
          .to_return(status: 200, body: "{\"ok\":true,\"result\":{\"id\":#{bot_id},\"first_name\":\"Chrispresso Customer Service\",\"username\":\"ChrispressoBot\"}}", headers: {})

        stub_request(:post, "https://api.telegram.org:443/bot#{token}/setWebhook")
          .with(body: { 'url' => "https://somehost.example.com/api/v1/channels_telegram_webhook/callback_token?bid=#{bot_id}" })
          .to_return(status: 400, body: '{"ok":false,"error_code":400,"description":"Bad Request: bad webhook: getaddrinfo: Name or service not known"}', headers: {})

        expect do
          Telegram.create_or_update_channel(token, { group_id: group_id, welcome: 'hi!', goodbye: 'goodbye' })
        end.to raise_error(Exceptions::UnprocessableEntity)
      end

      it 'with https, valid token, host and port' do

        Setting.set('http_type', 'https')
        Setting.set('fqdn', 'example.com')
        UserInfo.current_user_id = 1

        stub_request(:post, "https://api.telegram.org:443/bot#{token}/getMe")
          .to_return(status: 200, body: "{\"ok\":true,\"result\":{\"id\":#{bot_id},\"first_name\":\"Chrispresso Customer Service\",\"username\":\"ChrispressoBot\"}}", headers: {})

        stub_request(:post, "https://api.telegram.org:443/bot#{token}/setWebhook")
          .with(body: { 'url' => "https://example.com/api/v1/channels_telegram_webhook/callback_token?bid=#{bot_id}" })
          .to_return(status: 200, body: '{"ok":true,"result":true,"description":"Webhook was set"}', headers: {})

        channel = Telegram.create_or_update_channel(token, { group_id: group_id, welcome: 'hi!', goodbye: 'goodbye' })
        expect(channel).to be_truthy
      end
    end

    describe 'communication' do
      before do
        UserInfo.current_user_id = 1
        Channel.where(area: 'Telegram::Bot').destroy_all
        Setting.set('http_type', 'https')
        Setting.set('fqdn', 'example.com')

        stub_request(:post, "https://api.telegram.org:443/bot#{token}/getMe")
          .to_return(status: 200, body: "{\"ok\":true,\"result\":{\"id\":#{bot_id},\"first_name\":\"Chrispresso Customer Service\",\"username\":\"ChrispressoBot\"}}", headers: {})

        stub_request(:post, "https://api.telegram.org:443/bot#{token}/setWebhook")
          .with(body: { 'url' => "https://example.com/api/v1/channels_telegram_webhook/callback_token?bid=#{bot_id}" })
          .to_return(status: 200, body: '{"ok":true,"result":true,"description":"Webhook was set"}', headers: {})

        stub_request(:post, "https://api.telegram.org:443/bot#{token2}/getMe")
          .to_return(status: 200, body: "{\"ok\":true,\"result\":{\"id\":#{bot_id2},\"first_name\":\"Chrispresso Customer Service\",\"username\":\"ChrispressoBot2\"}}", headers: {})

        stub_request(:post, "https://api.telegram.org:443/bot#{token2}/setWebhook")
          .with(body: { 'url' => "https://example.com/api/v1/channels_telegram_webhook/callback_token?bid=#{bot_id2}" })
          .to_return(status: 200, body: '{"ok":true,"result":true,"description":"Webhook was set"}', headers: {})
      end

      let!(:channel) { Telegram.create_or_update_channel(token, { group_id: group_id, welcome: 'hi!', goodbye: 'goodbye' }) }
      let!(:channel2) { Telegram.create_or_update_channel(token2, { group_id: group_id2, welcome: 'hi!', goodbye: 'goodbye' }) }
      let!(:callback_url)  { "/api/v1/channels_telegram_webhook/#{channel.options[:callback_token]}?bid=#{channel.options[:bot][:id]}" }
      let!(:callback_url2) { "/api/v1/channels_telegram_webhook/#{channel2.options[:callback_token]}?bid=#{channel2.options[:bot][:id]}" }

      describe 'private' do
        before do
          init_mocks
        end

        it 'no found message' do
          post '/api/v1/channels_telegram_webhook', params: read_message('private', 'start'), as: :json
          expect(response).to have_http_status(:not_found)
        end

        it 'bot id is missing' do
          post '/api/v1/channels_telegram_webhook/not_existing', params: read_message('private', 'start'), as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['error']).to eq('bot id is missing')
        end

        it 'invalid callback token' do
          callback_url = "/api/v1/channels_telegram_webhook/not_existing?bid=#{channel.options[:bot][:id]}"
          post callback_url, params: read_message('private', 'start'), as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['error']).to eq('invalid callback token')
        end

        it 'start message' do
          post callback_url, params: read_message('private', 'start'), as: :json
          expect(response).to have_http_status(:ok)
        end

        it 'text message' do
          post callback_url, params: read_message('private', 'text'), as: :json
          expect(response).to have_http_status(:ok)
          ticket = Ticket.last
          expect(ticket.title).to eq('Hello, I need your Help')
          expect(ticket.state.name).to eq('new')
          expect(ticket.articles.count).to eq(1)
          expect(ticket.articles.first.body).to eq('Hello, I need your Help')
          expect(ticket.articles.first.content_type).to eq('text/plain')
        end

        it 'ignore same text message' do
          post callback_url, params: read_message('private', 'text'), as: :json
          expect(response).to have_http_status(:ok)

          post callback_url, params: read_message('private', 'text'), as: :json
          expect(response).to have_http_status(:ok)
          ticket = Ticket.last
          expect(ticket.title).to eq('Hello, I need your Help')
          expect(ticket.state.name).to eq('new')
          expect(ticket.articles.count).to eq(1)
          expect(ticket.articles.first.body).to eq('Hello, I need your Help')
          expect(ticket.articles.first.content_type).to eq('text/plain')
        end

        it 'document message' do
          post callback_url, params: read_message('private', 'document'), as: :json
          expect(response).to have_http_status(:ok)
          ticket = Ticket.last
          expect(ticket.articles.last.body).to match(%r{<img style="width:200px;height:200px;"}i)
          expect(ticket.articles.last.content_type).to eq('text/html')
          expect(ticket.articles.last.attachments.count).to eq(1)
          expect(Store.last.filename).to eq('document.pdf')
        end

        it 'photo message' do
          post callback_url, params: read_message('private', 'photo'), as: :json
          expect(response).to have_http_status(:ok)
          ticket = Ticket.last
          expect(ticket.articles.last.body).to match(%r{<img style="width:360px;height:327px;"}i)
          expect(ticket.articles.last.content_type).to eq('text/html')
        end

        it 'video message' do
          post callback_url, params: read_message('private', 'video'), as: :json
          expect(response).to have_http_status(:ok)
          ticket = Ticket.last
          expect(ticket.articles.count).to eq(1)
          expect(ticket.articles.last.body).to match(%r{<img style="}i)
          expect(ticket.articles.last.content_type).to eq('text/html')
          expect(ticket.articles.last.attachments.count).to eq(1)
          expect(Store.last.filename).to eq('video-videofileid.mp4')
        end

        it 'sticker message' do
          post callback_url, params: read_message('private', 'sticker'), as: :json
          expect(response).to have_http_status(:ok)
          ticket = Ticket.last

          if Rails.application.config.db_4bytes_utf8
            expect(ticket.title).to eq('😄')
          else
            expect(ticket.title).to eq('')
          end
          expect(ticket.state.name).to eq('new')
          expect(ticket.articles.count).to eq(1)
          expect(ticket.articles.last.body).to match(%r{<img style="}i)
          expect(ticket.articles.last.content_type).to eq('text/html')
          expect(ticket.articles.last.attachments.count).to eq(1)
          expect(Store.last.filename).to eq('HotCherry.webp')
        end

        it 'voice message' do
          post callback_url, params: read_message('private', 'voice'), as: :json
          expect(response).to have_http_status(:ok)
          ticket = Ticket.last
          expect(ticket.articles.count).to eq(1)
          expect(ticket.articles.last.content_type).to eq('text/html')
          expect(ticket.articles.last.attachments.count).to eq(1)
          expect(Store.last.filename).to eq('audio-voicefileid.ogg')
        end

        it 'end message' do
          post callback_url, params: read_message('private', 'text'), as: :json
          expect(response).to have_http_status(:ok)

          post callback_url, params: read_message('private', 'end'), as: :json
          expect(response).to have_http_status(:ok)
          ticket = Ticket.last
          expect(ticket.state.name).to eq('closed')
          expect(ticket.articles.count).to eq(1)
          expect(ticket.articles.last.body).to eq('Hello, I need your Help')
          expect(ticket.articles.last.content_type).to eq('text/plain')
        end
      end

      describe 'channel' do
        before do
          init_mocks
        end

        it 'start message' do
          post callback_url, params: read_message('channel', 'start'), as: :json
          expect(response).to have_http_status(:ok)
        end

        it 'text message' do
          post callback_url, params: read_message('channel', 'text'), as: :json
          expect(response).to have_http_status(:ok)
          ticket = Ticket.last
          expect(ticket.title).to eq('Hello, I need your Help')
          expect(ticket.state.name).to eq('new')
          expect(ticket.articles.count).to eq(1)
          expect(ticket.articles.first.body).to eq('Hello, I need your Help')
          expect(ticket.articles.first.content_type).to eq('text/plain')
        end

        it 'ignore same text message' do
          post callback_url, params: read_message('channel', 'text'), as: :json
          expect(response).to have_http_status(:ok)

          post callback_url, params: read_message('channel', 'text'), as: :json
          expect(response).to have_http_status(:ok)
          ticket = Ticket.last
          expect(ticket.title).to eq('Hello, I need your Help')
          expect(ticket.state.name).to eq('new')
          expect(ticket.articles.count).to eq(1)
          expect(ticket.articles.first.body).to eq('Hello, I need your Help')
          expect(ticket.articles.first.content_type).to eq('text/plain')
        end

        it 'document message' do
          post callback_url, params: read_message('channel', 'document'), as: :json
          expect(response).to have_http_status(:ok)
          ticket = Ticket.last
          expect(ticket.articles.last.body).to match(%r{<img style="width:200px;height:200px;"}i)
          expect(ticket.articles.last.content_type).to eq('text/html')
          expect(ticket.articles.last.attachments.count).to eq(1)
          expect(Store.last.filename).to eq('document.pdf')
        end

        it 'photo message' do
          post callback_url, params: read_message('channel', 'photo'), as: :json
          expect(response).to have_http_status(:ok)
          ticket = Ticket.last
          expect(ticket.articles.last.body).to match(%r{<img style="width:360px;height:327px;"}i)
          expect(ticket.articles.last.content_type).to eq('text/html')
        end

        it 'video message' do
          post callback_url, params: read_message('channel', 'video'), as: :json
          expect(response).to have_http_status(:ok)
          ticket = Ticket.last
          expect(ticket.articles.count).to eq(1)
          expect(ticket.articles.last.body).to match(%r{<img style="}i)
          expect(ticket.articles.last.content_type).to eq('text/html')
          expect(ticket.articles.last.attachments.count).to eq(1)
          expect(Store.last.filename).to eq('video-videofileid.mp4')
        end

        it 'sticker message' do
          post callback_url, params: read_message('channel', 'sticker'), as: :json
          expect(response).to have_http_status(:ok)
          ticket = Ticket.last

          if Rails.application.config.db_4bytes_utf8
            expect(ticket.title).to eq('😄')
          else
            expect(ticket.title).to eq('')
          end
          expect(ticket.state.name).to eq('new')
          expect(ticket.articles.count).to eq(1)
          expect(ticket.articles.last.body).to match(%r{<img style="}i)
          expect(ticket.articles.last.content_type).to eq('text/html')
          expect(ticket.articles.last.attachments.count).to eq(1)
          expect(Store.last.filename).to eq('HotCherry.webp')
        end

        it 'voice message' do
          post callback_url, params: read_message('channel', 'voice'), as: :json
          expect(response).to have_http_status(:ok)
          ticket = Ticket.last
          expect(ticket.articles.count).to eq(1)
          expect(ticket.articles.last.content_type).to eq('text/html')
          expect(ticket.articles.last.attachments.count).to eq(1)
          expect(Store.last.filename).to eq('audio-voicefileid.ogg')
        end

        it 'end message' do
          post callback_url, params: read_message('channel', 'text'), as: :json
          expect(response).to have_http_status(:ok)

          post callback_url, params: read_message('channel', 'end'), as: :json
          expect(response).to have_http_status(:ok)
          ticket = Ticket.last
          expect(ticket.state.name).to eq('closed')
          expect(ticket.articles.count).to eq(1)
          expect(ticket.articles.last.body).to eq('Hello, I need your Help')
          expect(ticket.articles.last.content_type).to eq('text/plain')
        end
      end

      it 'with two bots and different groups' do
        Ticket.destroy_all

        # send start message
        post callback_url, params: read_message('private', 'start'), as: :json
        expect(response).to have_http_status(:ok)

        # send text message
        post callback_url, params: read_message('private', 'text'), as: :json
        expect(response).to have_http_status(:ok)
        expect(Ticket.count).to eq(1)
        ticket1 = Ticket.last

        expect(ticket1.title).to eq('Hello, I need your Help')
        expect(ticket1.state.name).to eq('new')
        expect(ticket1.articles.count).to eq(1)
        expect(ticket1.articles.first.body).to eq('Hello, I need your Help')
        expect(ticket1.articles.first.content_type).to eq('text/plain')

        expect(ticket1.articles.first.from).to eq('Test Firstname Test Lastname')
        expect(ticket1.articles.first.to).to eq('@ChrispressoBot')

        # send start2 message
        post callback_url2, params: read_message('private', 'start2'), as: :json
        expect(response).to have_http_status(:ok)

        # send text2 message
        post callback_url2, params: read_message('private', 'text2'), as: :json
        expect(response).to have_http_status(:ok)
        expect(Ticket.count).to eq(2)

        ticket2 = Ticket.last
        expect(ticket2.title).to eq('Can you help me with my feature?')
        expect(ticket2.state.name).to eq('new')
        expect(ticket2.articles.count).to eq(1)
        expect(ticket2.articles.first.body).to eq('Can you help me with my feature?')
        expect(ticket2.articles.first.content_type).to eq('text/plain')

        expect(ticket2.articles.first.from).to eq('Test Firstname2 Test Lastname2')
        expect(ticket2.articles.first.to).to eq('@ChrispressoBot2')
      end

    end

    def read_message(type, file)
      JSON.parse(File.read(Rails.root.join('test', 'data', 'telegram', type, "#{file}.json")))
    end

    def init_mocks

      # create mocks for every file type
      %w[document documentthumb voice sticker stickerthumb video videothumb photo].each do |file|
        stub_request(:post, "https://api.telegram.org/bot#{token}/getFile")
          .with(body: { 'file_id' => "#{file}fileid" })
          .to_return(status: 200, body: "{\"result\":{\"file_size\":123456,\"file_id\":\"#{file}fileid\",\"file_path\":\"documentfile\"}}", headers: {})
        stub_request(:get, "https://api.telegram.org/file/bot#{token}/#{file}file")
          .to_return(status: 200, body: "#{file}file", headers: {})
      end

      [1, 2, 3].each do |id|
        stub_request(:post, "https://api.telegram.org/bot#{token}/getFile")
          .with(body: { 'file_id' => "photofileid#{id}" })
          .to_return(status: 200, body: "{\"result\":{\"file_size\":3622849,\"file_id\":\"photofileid#{id}\",\"file_path\":\"photofile\"}}", headers: {})
        stub_request(:get, "https://api.telegram.org/file/bot#{token}/photofile")
          .to_return(status: 200, body: 'photofile', headers: {})
      end
    end
  end
end
