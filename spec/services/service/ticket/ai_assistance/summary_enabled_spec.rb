# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::AIAssistance::SummaryEnabled do
  subject(:service) { execute_service }

  let(:agent)  { create(:agent, groups: [ticket.group]) }
  let(:ticket) { create(:ticket) }

  let(:matching_priority_condition) do
    {
      'ticket.priority_id' => {
        'operator' => 'is',
        'value'    => [ticket.priority.id.to_s],
      },
    }
  end

  def execute_service
    described_class.with_current_user(agent).execute(ticket:)
  end

  def configure_summary_selector(condition)
    Setting.set('ai_assistance_ticket_summary_selector', { 'condition' => condition })
  end

  def selector_cache_key(condition, include_current_user: false)
    condition = condition.merge(
      'ticket.id' => {
        'operator' => 'is',
        'value'    => ticket.id,
      }
    )

    [
      described_class.name,
      ticket.cache_key_with_version,
      include_current_user ? agent.cache_key_with_version : nil,
      Digest::SHA256.hexdigest(condition.to_json),
    ].compact.join('/')
  end

  def track_selector_cache_fetches
    fetched_keys = []

    allow(Rails.cache).to receive(:fetch).and_wrap_original do |method, key, *args, **kwargs, &block|
      fetched_keys << key if key.start_with?(described_class.name)

      method.call(key, *args, **kwargs, &block)
    end

    fetched_keys
  end

  before do
    allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(true)

    setup_ai_provider
    Setting.set('ai_assistance_ticket_summary', true)
  end

  context 'when no selector is configured' do
    it { is_expected.to be(true) }

    it 'does not evaluate selector conditions' do
      allow(Ticket).to receive(:selectors).and_call_original

      execute_service

      expect(Ticket).not_to have_received(:selectors)
    end

    it 'does not cache selector conditions' do
      allow(Rails.cache).to receive(:fetch).and_call_original

      execute_service

      expect(Rails.cache)
        .not_to have_received(:fetch)
        .with(a_string_starting_with(described_class.name))
    end
  end

  context 'when the feature is disabled' do
    before do
      Setting.set('ai_assistance_ticket_summary', false)
    end

    it { is_expected.to be(false) }
  end

  context 'when the selector matches' do
    before do
      configure_summary_selector(matching_priority_condition)
    end

    it { is_expected.to be(true) }
  end

  context 'when the selector does not match' do
    before do
      Setting.set('ai_assistance_ticket_summary_selector', {
                    'condition' => {
                      'ticket.priority_id' => {
                        'operator' => 'is',
                        'value'    => [Ticket::Priority.find_by(name: '3 high').id.to_s],
                      },
                    },
                  })
    end

    it { is_expected.to be(false) }
  end

  context 'when the enabled state was already computed' do
    before do
      configure_summary_selector(matching_priority_condition)

      allow(Ticket).to receive(:selectors).and_call_original
    end

    it 'uses the cached selector result' do
      2.times { execute_service }

      expect(Ticket).to have_received(:selectors).once
    end

    it 'does not include current user in the cache key for user-independent selectors' do
      fetched_keys = track_selector_cache_fetches

      execute_service

      expect(fetched_keys)
        .to satisfy { |keys| keys == [selector_cache_key(matching_priority_condition)] && keys.none? { |key| key.include?(agent.cache_key_with_version) } }
    end

    it 'recomputes the selector result after the ticket changes' do
      execute_service

      ticket.touch
      ticket.reload

      execute_service

      expect(Ticket).to have_received(:selectors).twice
    end

    it 'uses a permanent cache for ticket-local current user conditions' do
      ticket.update!(owner: agent)

      Setting.set('ai_assistance_ticket_summary_selector', {
                    'condition' => {
                      'ticket.owner_id' => {
                        'operator'      => 'is',
                        'pre_condition' => 'current_user.id',
                      },
                    },
                  })

      2.times { execute_service }

      expect(Ticket).to have_received(:selectors).once
    end

    it 'includes current user in the cache key when the selector uses current user conditions' do
      ticket.update!(owner: agent)

      condition = {
        'ticket.owner_id' => {
          'operator'      => 'is',
          'pre_condition' => 'current_user.id',
        },
      }
      configure_summary_selector(condition)

      allow(Rails.cache).to receive(:fetch).and_call_original

      execute_service

      expect(Rails.cache)
        .to have_received(:fetch)
        .with(selector_cache_key(condition, include_current_user: true))
    end

    it 'uses a permanent cache for ticket tag conditions' do
      ticket.tag_add('important', agent.id)

      Setting.set('ai_assistance_ticket_summary_selector', {
                    'condition' => {
                      'ticket.tags' => {
                        'operator' => 'contains one',
                        'value'    => 'important',
                      },
                    },
                  })

      2.times { execute_service }

      expect(Ticket).to have_received(:selectors).once
    end

    it 'uses a permanent cache for ticket mention conditions' do
      create(:mention, mentionable: ticket, user: agent)

      Setting.set('ai_assistance_ticket_summary_selector', {
                    'condition' => {
                      'ticket.mention_user_ids' => {
                        'operator'      => 'is',
                        'pre_condition' => 'current_user.id',
                      },
                    },
                  })

      2.times { execute_service }

      expect(Ticket).to have_received(:selectors).once
    end

    it 'uses a bounded cache for time-based selector conditions' do
      condition = {
        'ticket.created_at' => {
          'operator' => 'today',
        },
      }
      configure_summary_selector(condition)

      allow(Rails.cache).to receive(:fetch).and_call_original

      execute_service

      expect(Rails.cache)
        .to have_received(:fetch)
        .with(selector_cache_key(condition), expires_in: described_class::CACHE_EXPIRES_IN)
    end

    it 'uses a bounded cache for current user organization selector conditions' do
      condition = {
        'ticket.organization_id' => {
          'operator'      => 'is',
          'pre_condition' => 'current_user.organization_id',
        },
      }
      configure_summary_selector(condition)

      allow(Rails.cache).to receive(:fetch).and_call_original

      execute_service

      expect(Rails.cache)
        .to have_received(:fetch)
        .with(selector_cache_key(condition, include_current_user: true), expires_in: described_class::CACHE_EXPIRES_IN)
    end

    it 'uses a bounded cache for related record selector conditions' do
      condition = {
        'customer.firstname' => {
          'operator' => 'is',
          'value'    => [ticket.customer.firstname],
        },
      }
      configure_summary_selector(condition)

      allow(Rails.cache).to receive(:fetch).and_call_original

      execute_service

      expect(Rails.cache)
        .to have_received(:fetch)
        .with(selector_cache_key(condition), expires_in: described_class::CACHE_EXPIRES_IN)
    end

    it 'recomputes the selector result after the selector conditions change' do
      execute_service

      Setting.set('ai_assistance_ticket_summary_selector', {
                    'condition' => {
                      'ticket.priority_id' => {
                        'operator' => 'is',
                        'value'    => [Ticket::Priority.find_by(name: '3 high').id.to_s],
                      },
                    },
                  })

      expect(execute_service).to be(false)
    end
  end
end
