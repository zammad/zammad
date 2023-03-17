# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::AutoResponseCheck, type: :channel_filter do
  let(:mail) do
    {
      From: 'me@example.com'
    }
  end

  shared_examples 'check auto response header' do |send_auto_response_state, is_auto_response_state|
    let(:mail_auto_response) do
      {
        'x-zammad-send-auto-response':  send_auto_response_state,
        'x-zammad-is-auto-response':    is_auto_response_state,
        'x-zammad-article-preferences': {
          'send-auto-response' => send_auto_response_state,
          'is-auto-response'   => is_auto_response_state
        }
      }
    end

    it 'check filter result' do
      filter(mail)
      expect(mail).to include(mail_auto_response)
    end
  end

  context 'with no blocking response header' do
    include_examples 'check auto response header', true, false
  end

  context 'with no blocking response header and x-zammad-send-auto-response:false' do
    let(:mail) do
      {
        'x-zammad-send-auto-response': 'false'
      }
    end

    include_examples 'check auto response header', false, false
  end

  context 'with blocking auto response header' do
    context 'with header precedence:list' do
      let(:mail) do
        {
          precedence: 'list'
        }
      end

      include_examples 'check auto response header', false, true
    end

    context 'with header precedence:list and x-zammad-send-auto-response:true' do
      let(:mail) do
        {
          precedence:                    'list',
          'x-zammad-send-auto-response': 'true'
        }
      end

      include_examples 'check auto response header', true, true
    end

    context 'with header precedence:list and x-zammad-send-auto-response:false' do
      let(:mail) do
        {
          precedence:                    'list',
          'x-zammad-send-auto-response': 'false'
        }
      end

      include_examples 'check auto response header', false, true
    end

    context 'with header precedence:list and x-zammad-is-auto-response:false' do
      let(:mail) do
        {
          precedence:                  'list',
          'x-zammad-is-auto-response': 'false'
        }
      end

      include_examples 'check auto response header', true, false
    end

    context 'with header precedence:list, x-zammad-is-auto-response:false and x-zammad-send-auto-response:false' do
      let(:mail) do
        {
          precedence:                    'list',
          'x-zammad-is-auto-response':   'false',
          'x-zammad-send-auto-response': 'false'
        }
      end

      include_examples 'check auto response header', false, false
    end

    context 'with header precedence:list, x-zammad-is-auto-response:true and x-zammad-send-auto-response:true' do
      let(:mail) do
        {
          precedence:                    'list',
          'x-zammad-is-auto-response':   'true',
          'x-zammad-send-auto-response': 'true'
        }
      end

      include_examples 'check auto response header', true, true
    end
  end
end
