# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'FormUpdater::AppliesChatSession' do
  context 'when applying a chat session' do
    let(:meta)         { { initial: true, form_id: SecureRandom.uuid, additional_data: } }
    let(:chat_session) { create(:'chat/session', chat: create(:chat), user: user, created_at: Time.zone.parse('2026-03-04 14:05:00 UTC')) }
    let(:session_url)  { "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#customer_chat/session/#{chat_session.id}" }

    let(:additional_data) { { 'chatSessionId' => Gql::ZammadSchema.id_from_object(chat_session) } }

    let(:fields) { resolved_result.resolve[:fields] }

    it 'sets the start of the chat as title' do
      expect(fields).to include('title' => include(value: "Chat from #{Translation.timestamp(user.locale, 'UTC', chat_session.created_at, append_timezone: false)}"))
    end

    it 'sets a link to the chat session as body' do
      expect(fields).to include('body' => include(value: "<a href=\"#{session_url}\">#{session_url}</a>"))
    end

    context 'with an FQDN holding a character HTML has to escape' do
      before { Setting.set('fqdn', 'zammad.example.com&') }

      it 'escapes it in the link' do
        expect(fields.dig('body', :value)).to include('zammad.example.com&amp;/').and not_include('zammad.example.com&/')
      end
    end

    it 'leaves the tags alone while the chat has none' do
      expect(fields.dig('tags', :value)).to be_nil
    end

    context 'with tags on the chat session' do
      before do
        chat_session.tag_add('billing', user.id)
        chat_session.tag_add('urgent', user.id)
      end

      it 'carries them over to the ticket' do
        expect(fields).to include('tags' => include(value: %w[billing urgent]))
      end
    end

    context 'with the agent in another locale and the system in another time zone' do
      before do
        user.preferences[:locale] = 'de-de'
        user.save!
        Setting.set('timezone_default', 'Europe/Berlin')
      end

      it 'formats the start in both' do
        expect(fields).to include('title' => include(value: Translation.translate('de-de', 'Chat from %s', '04.03.2026 15:05')))
      end
    end

    context 'without a chat session' do
      let(:additional_data) { {} }

      it 'sets neither title nor body' do
        expect(fields.dig('title', :value) || fields.dig('body', :value)).to be_nil
      end
    end

    context 'with an unknown chat session' do
      let(:additional_data) { { 'chatSessionId' => Gql::ZammadSchema.id_from_internal_id(Chat::Session, 0) } }

      it 'sets neither title nor body' do
        expect(fields.dig('title', :value) || fields.dig('body', :value)).to be_nil
      end
    end

    # As in the old UI, where any chat agent turns a session they opened into a ticket.
    context 'with a chat session of another agent' do
      let(:chat_session) { create(:'chat/session', chat: create(:chat), user: create(:agent)) }

      it 'sets title and body as well' do
        expect(fields).to include(
          'title' => include(value: start_with('Chat from')),
          'body'  => include(value: "<a href=\"#{session_url}\">#{session_url}</a>"),
        )
      end
    end

    context 'without the chat permission' do
      let(:user) { create(:user, roles: [create(:role, :agent)], groups: [group]) }

      it 'sets neither title nor body' do
        expect(fields.dig('title', :value) || fields.dig('body', :value)).to be_nil
      end
    end

    context 'when it is not the first round trip' do
      let(:meta) { { initial: false, form_id: SecureRandom.uuid, additional_data: } }

      it 'sets neither title nor body' do
        expect(fields.dig('title', :value) || fields.dig('body', :value)).to be_nil
      end
    end
  end
end
