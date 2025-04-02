# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'rack/handler/puma'

# this cop is disabled to speed up testing by avoiding the overhead of multiple requests

RSpec.describe UserAgent, :aggregate_failures, integration: true do
  include ZammadSpecSupportRequest

  def host_with_port
    host = 'http://localhost:3000'

    if ENV['CI'].present?
      host = 'http://build:3000'
    end

    host
  end

  puma_thread = nil

  # we need a running web server, otherwise the requests will fail
  before :all do # rubocop:disable RSpec/BeforeAfterAll
    ENV['CI_BASIC_AUTH_USER']     = 'basic_auth_user'
    ENV['CI_BASIC_AUTH_PASSWORD'] = 'test123'
    ENV['CI_BEARER_TOKEN']        = 'test_bearer_123'

    puma_thread = Thread.new do
      app = Rack::Builder.new do
        map '/' do
          run Rails.application
        end
      end.to_app
      Rack::Handler::Puma.run app, Port: 3000
    end

    sleep 0.25

    # wait for server to start
    server_started = false
    10.times do
      next if server_started

      server_started = system("curl -sSf #{host_with_port} > /dev/null")
      sleep 0.2 if !server_started
    end
  end

  after :all do # rubocop:disable RSpec/BeforeAfterAll
    puma_thread.kill
  end

  shared_context 'when doing user agent tests' do
    let(:host) { host_with_port }

    shared_examples 'successful request' do
      it 'returns a response' do
        expect(response).to be_success
        expect(response.code).to eq(code)
      end
    end

    shared_examples 'successful request with json body' do
      it 'returns a response' do
        expect(response).to be_success
        expect(response.code).to eq(code)
        expect(json_response).to include(expected_body)
      end
    end

    shared_examples 'successful get request' do
      it 'returns a response' do
        expect(response).to be_success
        expect(response.code).to eq(code)
        expect(response.header).to include('content-type' => content_type)
        expect(json_response).to include(expected_body)
      end
    end

    shared_examples 'successful post/put/patch request' do
      include_examples 'successful request with json body'
    end

    shared_examples 'successful delete request' do
      include_examples 'successful request with json body'
    end

    shared_examples 'successful redirect request' do
      include_examples 'successful request with json body'
    end

    shared_examples 'unsuccessful request with body' do
      it 'returns a response' do
        expect(response).not_to be_success
        expect(response.code).to eq(code)
        expect(response.body).to be_present
      end
    end

    shared_examples 'unsuccessful request without body' do
      it 'returns a response' do
        expect(response).not_to be_success
        expect(response.code).to eq(code)
        expect(response.body).to be_nil
      end
    end

    shared_examples 'unsuccessful get/post/put/delete request' do
      it 'returns a response' do
        expect(response).not_to be_success
        expect(response.code).to eq(code)
        expect(response.body).to eq(expected_body)
      end
    end

    describe '#get' do
      context 'without http basic auth' do
        subject(:response) { described_class.get(request_url, {}, options) }

        let(:options) { {} }

        context 'with code 200' do
          let(:code)          { '200' }
          let(:content_type)  { 'application/json; charset=utf-8' }
          let(:request_url)   { "#{host}/test/get/1?submitted=123" }
          let(:expected_body) do
            {
              'method'                 => 'get',
              'submitted'              => '123',
              'content_type_requested' => nil,
            }
          end

          include_examples 'successful get request'
        end

        context 'with code 202' do
          let(:code)         { '202' }
          let(:content_type) { 'application/json; charset=utf-8' }
          let(:request_url)  { "#{host}/test/get_accepted/1?submitted=123" }
          let(:expected_body) do
            {
              'method'                 => 'get',
              'submitted'              => '123',
              'content_type_requested' => nil,
            }
          end

          include_examples 'successful get request'
        end

        context 'with code 301' do
          let(:code)          { '200' }
          let(:content_type)  { 'application/json; charset=utf-8' }
          let(:request_url)   { "#{host}/test/redirect" }
          let(:expected_body) do
            {
              'method'                 => 'get',
              'submitted'              => 'abc',
              'content_type_requested' => nil,
            }
          end

          include_examples 'successful redirect request'
        end

        context 'with code 301, but suppressed redirection' do
          let(:code)          { 0 }
          let(:request_url)   { "#{host}/test/redirect" }
          let(:options)       { { do_not_follow_redirects: true } }

          include_examples 'unsuccessful request without body'
        end

        context 'with code 404' do
          let(:code)        { '404' }
          let(:request_url) { "#{host}/test/not_existing" }

          include_examples 'unsuccessful request with body'
        end
      end

      context 'with http basic auth' do
        subject(:response) do
          described_class.get(request_url, {}, {
                                user:     'basic_auth_user',
                                password: password,
                              })
        end

        context 'with code 200' do
          let(:code)          { '200' }
          let(:content_type)  { 'application/json; charset=utf-8' }
          let(:request_url)   { "#{host}/test_basic_auth/get/1?submitted=123" }
          let(:password)      { 'test123' }
          let(:expected_body) do
            {
              'method'                 => 'get',
              'submitted'              => '123',
              'content_type_requested' => nil,
            }
          end

          include_examples 'successful get request'
        end

        context 'with code 401' do
          let(:code)          { '401' }
          let(:request_url)   { "#{host}/test_basic_auth/get/1?submitted=123" }
          let(:password)      { 'test<>123' }
          let(:expected_body) { "HTTP Basic: Access denied.\n" }

          include_examples 'unsuccessful get/post/put/delete request'
        end
      end

      context 'with bearer token auth' do
        subject(:response) do
          described_class.get(request_url, {}, {
                                bearer_token: bearer_token,
                              })
        end

        context 'with code 200' do
          let(:code)          { '200' }
          let(:content_type)  { 'application/json; charset=utf-8' }
          let(:request_url)   { "#{host}/test_bearer_auth/get/1?submitted=123" }
          let(:bearer_token)  { 'test_bearer_123' }
          let(:expected_body) do
            {
              'method'                 => 'get',
              'submitted'              => '123',
              'content_type_requested' => nil,
            }
          end

          include_examples 'successful get request'
        end

        context 'with code 401' do
          let(:code)          { '401' }
          let(:request_url)   { "#{host}/test_bearer_auth/get/1?submitted=123" }
          let(:bearer_token)  { 'wrong_test_bearer' }
          let(:expected_body) { "HTTP Token: Access denied.\n" }

          include_examples 'unsuccessful get/post/put/delete request'
        end
      end

      context 'when timeouts are raised' do
        subject(:response) do
          described_class.get(request_url, {}, {
                                open_timeout: 0,
                                read_timeout: 0,
                              })
        end

        let(:request_url) { "#{host}/test/get/1?submitted=123" }
        let(:code)        { 0 }

        include_examples 'unsuccessful request without body'
      end

      context 'with content type set to json' do
        subject(:response) { described_class.get(request_url, request_params, request_options) }

        context 'with code 200' do
          let(:code)            { '200' }
          let(:content_type)    { 'application/json; charset=utf-8' }
          let(:request_url)     { "#{host}/test/get/1" }
          let(:request_params)  { { submitted: 'some value' } }
          let(:request_options) { { json: true } }
          let(:expected_body) do
            {
              'method'                 => 'get',
              'content_type_requested' => nil,
              'submitted'              => 'some value',
            }
          end

          include_examples 'successful get request'
        end

        context 'with code 404' do
          let(:code)            { '404' }
          let(:request_url)     { "#{host}/test/not_existing" }
          let(:request_params)  { { submitted: { key: 'some value' } } }
          let(:request_options) { { json: true } }

          include_examples 'unsuccessful request with body'
        end
      end
    end

    describe '#post' do
      context 'without http basic auth' do
        subject(:response) { described_class.post(request_url, request_params, request_options) }

        let(:request_options) { {} }

        context 'with code 201' do
          let(:code)           { '201' }
          let(:request_url)    { "#{host}/test/post/1" }
          let(:request_params) { { submitted: 'some value' } }
          let(:expected_body) do
            {
              'method'                 => 'post',
              'submitted'              => 'some value',
              'body'                   => ['submitted=some+value'],
              'content_type_requested' => 'application/x-www-form-urlencoded',
            }
          end

          include_examples 'successful post/put/patch request'
        end

        context 'with raw body' do
          let(:code) { '201' }
          let(:request_url)     { "#{host}/test/post/1" }
          let(:request_params)  { {} }
          let(:request_options) { { send_as_raw_body: 'raw body' } }
          let(:expected_body) do
            {
              'method'                 => 'post',
              'submitted'              => nil,
              'body'                   => ['raw body'],
              'content_type_requested' => 'application/x-www-form-urlencoded',
            }
          end

          include_examples 'successful post/put/patch request'
        end

        context 'with code 404' do
          let(:code)           { '404' }
          let(:request_url)    { "#{host}/test/not_existing" }
          let(:request_params) { { submitted: 'some value' } }

          include_examples 'unsuccessful request with body'
        end
      end

      context 'with http basic auth' do
        subject(:response) do
          described_class.post(request_url, request_params, {
                                 user:     'basic_auth_user',
                                 password: password,
                               })
        end

        context 'with code 201' do
          let(:code)           { '201' }
          let(:request_url)    { "#{host}/test_basic_auth/post/1" }
          let(:request_params) { { submitted: 'some value' } }
          let(:password)       { 'test123' }
          let(:expected_body) do
            {
              'method'                 => 'post',
              'submitted'              => 'some value',
              'content_type_requested' => 'application/x-www-form-urlencoded',
            }
          end

          include_examples 'successful post/put/patch request'
        end

        context 'with code 401' do
          let(:code)           { '401' }
          let(:request_url)    { "#{host}/test_basic_auth/post/1" }
          let(:request_params) { { submitted: 'some value' } }
          let(:password)       { 'test<>123' }
          let(:expected_body)  { "HTTP Basic: Access denied.\n" }

          include_examples 'unsuccessful get/post/put/delete request'
        end
      end

      context 'with bearer token auth' do
        subject(:response) do
          described_class.post(request_url, request_params, {
                                 bearer_token: bearer_token,
                               })
        end

        context 'with code 201' do
          let(:code) { '201' }
          let(:request_url)    { "#{host}/test_bearer_auth/post/1" }
          let(:request_params) { { submitted: 'some value' } }
          let(:bearer_token)   { 'test_bearer_123' }
          let(:expected_body) do
            {
              'method'                 => 'post',
              'submitted'              => 'some value',
              'content_type_requested' => 'application/x-www-form-urlencoded',
            }
          end

          include_examples 'successful post/put/patch request'
        end

        context 'with code 401' do
          let(:code) { '401' }
          let(:request_url)    { "#{host}/test_bearer_auth/post/1" }
          let(:request_params) { { submitted: 'some value' } }
          let(:bearer_token)   { 'wrong_test_bearer' }
          let(:expected_body)  { "HTTP Token: Access denied.\n" }

          include_examples 'unsuccessful get/post/put/delete request'
        end
      end

      context 'when timeouts are raised' do
        subject(:response) do
          described_class.post(request_url, request_params, {
                                 open_timeout: 0,
                                 read_timeout: 0,
                               })
        end

        let(:request_url) { "#{host}/test/post/1" }
        let(:request_params) { { submitted: 'timeout' } }
        let(:code)           { 0 }

        include_examples 'unsuccessful request without body'
      end

      context 'with content type set to json' do
        subject(:response) { described_class.post(request_url, request_params, request_options) }

        context 'with code 201' do
          let(:code)            { '201' }
          let(:content_type)    { 'application/json; charset=utf-8' }
          let(:request_url)     { "#{host}/test/post/1" }
          let(:request_params)  { { submitted: { key: 'some value' } } }
          let(:request_options) { { json: true } }
          let(:expected_body) do
            {
              'method'                 => 'post',
              'content_type_requested' => 'application/json',
              'submitted'              => {
                'key' => 'some value',
              },
            }
          end

          include_examples 'successful post/put/patch request'
        end
      end
    end

    describe '#put' do
      subject(:response) { described_class.put(request_url, request_params) }

      context 'without http basic auth' do
        context 'with code 200' do
          let(:code)           { '200' }
          let(:request_url)    { "#{host}/test/put/1" }
          let(:request_params) { { submitted: 'some value' } }

          let(:expected_body) do
            {
              'method'                 => 'put',
              'submitted'              => 'some value',
              'content_type_requested' => 'application/x-www-form-urlencoded',
            }
          end

          include_examples 'successful post/put/patch request'
        end

        context 'with code 404' do
          let(:code)           { '404' }
          let(:request_url)    { "#{host}/test/not_existing" }
          let(:request_params) { { submitted: 'some value' } }

          include_examples 'unsuccessful request with body'
        end
      end

      context 'with http basic auth' do
        subject(:response) do
          described_class.put(request_url, request_params, {
                                user:     'basic_auth_user',
                                password: password,
                              })
        end

        let(:password)     { 'test123' }
        let(:submit_value) { 'some value' }

        context 'with code 200' do
          let(:code)           { '200' }
          let(:request_url)    { "#{host}/test_basic_auth/put/1" }
          let(:request_params) { { submitted: 'some value' } }
          let(:expected_body) do
            {
              'method'                 => 'put',
              'submitted'              => 'some value',
              'content_type_requested' => 'application/x-www-form-urlencoded',
            }
          end

          include_examples 'successful post/put/patch request'
        end

        context 'with code 401' do
          let(:code)           { '401' }
          let(:request_url)    { "#{host}/test_basic_auth/put/1" }
          let(:request_params) { { submitted: 'some value' } }
          let(:password)       { 'test<>123' }
          let(:expected_body)  { "HTTP Basic: Access denied.\n" }

          include_examples 'unsuccessful get/post/put/delete request'
        end
      end

      context 'with bearer token auth' do
        subject(:response) do
          described_class.put(request_url, request_params, {
                                bearer_token: bearer_token,
                              })
        end

        context 'with code 200' do
          let(:code) { '200' }
          let(:request_url)    { "#{host}/test_bearer_auth/put/1" }
          let(:request_params) { { submitted: 'some value' } }
          let(:bearer_token)   { 'test_bearer_123' }
          let(:expected_body) do
            {
              'method'                 => 'put',
              'submitted'              => 'some value',
              'content_type_requested' => 'application/x-www-form-urlencoded',
            }
          end

          include_examples 'successful post/put/patch request'
        end

        context 'with code 401' do
          let(:code) { '401' }
          let(:request_url)    { "#{host}/test_bearer_auth/put/1" }
          let(:request_params) { { submitted: 'some value' } }
          let(:bearer_token)   { 'wrong_test_bearer' }
          let(:expected_body)  { "HTTP Token: Access denied.\n" }

          include_examples 'unsuccessful get/post/put/delete request'
        end
      end
    end

    describe '#patch' do
      subject(:response) { described_class.patch(request_url, request_params) }

      context 'with code 200' do
        let(:code)           { '200' }
        let(:request_url)    { "#{host}/test/patch/1" }
        let(:request_params) { { submitted: 'some value' } }

        let(:expected_body) do
          {
            'method'                 => 'patch',
            'submitted'              => 'some value',
            'content_type_requested' => 'application/x-www-form-urlencoded',
          }
        end

        include_examples 'successful post/put/patch request'
      end

      context 'with code 404' do
        let(:code)           { '404' }
        let(:request_url)    { "#{host}/test/not_existing" }
        let(:request_params) { { submitted: 'some value' } }

        include_examples 'unsuccessful request with body'
      end
    end

    describe '#delete' do
      context 'without http basic auth' do
        subject(:response) { described_class.delete(request_url) }

        context 'with code 200' do
          let(:code)          { '200' }
          let(:request_url)   { "#{host}/test/delete/1" }
          let(:expected_body) do
            {
              'method'                 => 'delete',
              'content_type_requested' => nil,
            }
          end

          include_examples 'successful delete request'
        end

        context 'with code 404' do
          let(:code)        { '404' }
          let(:request_url) { "#{host}/test/not_existing" }

          include_examples 'unsuccessful request with body'
        end
      end

      context 'with http basic auth' do
        subject(:response) do
          described_class.delete(request_url, {}, {
                                   user:     'basic_auth_user',
                                   password: password,
                                 })
        end

        context 'with code 200' do
          let(:code)          { '200' }
          let(:content_type)  { 'application/json; charset=utf-8' }
          let(:request_url)   { "#{host}/test_basic_auth/delete/1" }
          let(:password)      { 'test123' }
          let(:expected_body) do
            {
              'method'                 => 'delete',
              'content_type_requested' => nil,
            }
          end

          include_examples 'successful delete request'
        end

        context 'with code 401' do
          let(:code)          { '401' }
          let(:request_url)   { "#{host}/test_basic_auth/delete/1" }
          let(:password)      { 'test<>123' }
          let(:expected_body) { "HTTP Basic: Access denied.\n" }

          include_examples 'unsuccessful get/post/put/delete request'
        end
      end

      context 'with bearer token auth' do
        subject(:response) do
          described_class.delete(request_url, {}, {
                                   bearer_token: bearer_token,
                                 })
        end

        context 'with code 200' do
          let(:code) { '200' }
          let(:content_type)   { 'application/json; charset=utf-8' }
          let(:request_url)    { "#{host}/test_bearer_auth/delete/1" }
          let(:request_params) { { submitted: 'some value' } }
          let(:bearer_token)   { 'test_bearer_123' }
          let(:expected_body) do
            {
              'method'                 => 'delete',
              'content_type_requested' => nil,
            }
          end

          include_examples 'successful delete request'
        end

        context 'with code 401' do
          let(:code) { '401' }
          let(:request_url)    { "#{host}/test_bearer_auth/delete/1" }
          let(:request_params) { { submitted: 'some value' } }
          let(:bearer_token)   { 'wrong_test_bearer' }
          let(:expected_body)  { "HTTP Token: Access denied.\n" }

          include_examples 'unsuccessful get/post/put/delete request'
        end
      end
    end
  end

  describe 'testing without proxy' do
    include_context 'when doing user agent tests'
  end

  describe 'testing with proxy', required_envs: %w[CI_PROXY_URL CI_PROXY_USER CI_PROXY_PASSWORD] do
    before do
      Setting.set('proxy', ENV['CI_PROXY_URL'])
      Setting.set('proxy_username', ENV['CI_PROXY_USER'])
      Setting.set('proxy_password', ENV['CI_PROXY_PASSWORD'])
    end

    include_context 'when doing user agent tests'
  end
end
