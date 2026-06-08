# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Template::Interpolation::Interpolator, :aggregate_failures do
  describe '.tracks' do
    context 'when called on the base Interpolator class' do
      it 'returns an array of track classes' do
        expect(described_class.tracks).to be_an(Array)
      end

      it 'includes only track classes that start with the correct namespace' do
        described_class.tracks.each do |track|
          expect(track.name).to start_with('Service::Template::Interpolation::Engine::Track')
        end
      end

      it 'includes base track classes' do
        track_names = described_class.tracks.map(&:name)

        expect(track_names).to include(
          'Service::Template::Interpolation::Engine::Track::Ticket',
          'Service::Template::Interpolation::Engine::Track::Ticket::Article',
          'Service::Template::Interpolation::Engine::Track::User',
          'Service::Template::Interpolation::Engine::Track::Group',
          'Service::Template::Interpolation::Engine::Track::Organization',
          'Service::Template::Interpolation::Engine::Track::Config',
        )
      end

      it 'includes nested track classes' do
        track_names = described_class.tracks.map(&:name)

        expect(track_names).to include(
          'Service::Template::Interpolation::Engine::Track::Ticket::Priority',
          'Service::Template::Interpolation::Engine::Track::Ticket::State',
          'Service::Template::Interpolation::Engine::Track::Ticket::Article::Sender',
          'Service::Template::Interpolation::Engine::Track::Ticket::Article::Type',
        )
      end

      it 'excludes track classes from subclass-specific namespaces' do
        track_names = described_class.tracks.map(&:name)

        expect(track_names).not_to include(
          'Service::Template::Interpolation::Interpolator::Webhook::Track::Notification',
          'Service::Template::Interpolation::Interpolator::Webhook::Track::PreDefinedWebhook',
          'Service::Template::Interpolation::Interpolator::AIAgent::Track::AIAgentResult',
        )
      end

      it 'does not include custom tracks for base class' do
        custom_track_count = described_class.custom_tracks.count

        expect(custom_track_count).to eq(0)
      end

      it 'memoizes the result on subsequent calls' do
        first_call = described_class.tracks
        second_call = described_class.tracks

        expect(first_call.object_id).to eq(second_call.object_id)
      end

      it 'returns all descendants of Service::Template::Interpolation::Engine::Track' do
        base_track = Service::Template::Interpolation::Engine::Track
        all_descendants = base_track.descendants.select { |k| k.name.starts_with?('Service::Template::Interpolation::Engine::Track') }

        expect(described_class.tracks).to match_array(all_descendants)
      end
    end

    context 'when called on Webhook subclass' do
      subject(:webhook_interpolator) { Service::Template::Interpolation::Interpolator::Webhook }

      it 'includes base track classes' do
        track_names = webhook_interpolator.tracks.map(&:name)

        expect(track_names).to include('Service::Template::Interpolation::Engine::Track::Ticket')
      end

      it 'includes webhook-specific custom tracks' do
        track_names = webhook_interpolator.tracks.map(&:name)

        expect(track_names).to include(
          'Service::Template::Interpolation::Interpolator::Webhook::Track::Notification',
          'Service::Template::Interpolation::Interpolator::Webhook::Track::PreDefinedWebhook',
        )
      end

      it 'has custom_tracks defined' do
        expect(webhook_interpolator.custom_tracks).to eq([
                                                           Service::Template::Interpolation::Interpolator::Webhook::Track::PreDefinedWebhook,
                                                           Service::Template::Interpolation::Interpolator::Webhook::Track::Notification
                                                         ])
      end

      it 'combines base tracks with custom tracks' do
        expected_count = Service::Template::Interpolation::Engine::Track.descendants.count { |k| k.name.starts_with?('Service::Template::Interpolation::Engine::Track') } + 2

        expect(webhook_interpolator.tracks.count).to eq(expected_count)
      end
    end

    context 'when called on AIAgent subclass' do
      subject(:ai_agent_interpolator) { Service::Template::Interpolation::Interpolator::AIAgent }

      it 'includes base track classes' do
        track_names = ai_agent_interpolator.tracks.map(&:name)

        expect(track_names).to include('Service::Template::Interpolation::Engine::Track::Ticket')
      end

      it 'includes AI agent-specific custom tracks' do
        track_names = ai_agent_interpolator.tracks.map(&:name)

        expect(track_names).to include('Service::Template::Interpolation::Interpolator::AIAgent::Track::AIAgentResult')
      end

      it 'has custom_tracks defined' do
        expect(ai_agent_interpolator.custom_tracks).to eq([
                                                            Service::Template::Interpolation::Interpolator::AIAgent::Track::AIAgentResult
                                                          ])
      end

      it 'combines base tracks with custom tracks' do
        expected_count = Service::Template::Interpolation::Engine::Track.descendants.count { |k| k.name.starts_with?('Service::Template::Interpolation::Engine::Track') } + 1

        expect(ai_agent_interpolator.tracks.count).to eq(expected_count)
      end
    end

    context 'when verifying track class properties' do
      it 'all returned tracks are classes' do
        expect(described_class.tracks).to all(be_a(Class))
      end

      it 'all returned tracks inherit from Service::Template::Interpolation::Engine::Track' do
        described_class.tracks.each do |track|
          expect(track.ancestors).to include(Service::Template::Interpolation::Engine::Track)
        end
      end

      it 'all returned tracks have a klass method' do
        expect(described_class.tracks).to all(respond_to(:klass))
      end

      it 'all returned tracks have a functions method' do
        expect(described_class.tracks).to all(respond_to(:functions))
      end

      it 'all returned tracks have a root? method' do
        expect(described_class.tracks).to all(respond_to(:root?))
      end
    end
  end

  describe '.custom_tracks' do
    it 'returns an empty array for base class' do
      expect(described_class.custom_tracks).to eq([])
    end

    it 'can be overridden by subclasses' do
      expect(Service::Template::Interpolation::Interpolator::Webhook.custom_tracks).not_to be_empty
      expect(Service::Template::Interpolation::Interpolator::AIAgent.custom_tracks).not_to be_empty
    end
  end
end
