# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

class AI::Provider::SampleProvider < AI::Provider
  def chat(prompt_system:, prompt_user:, prompt_image:)
    { response: "System: #{prompt_system}\nUser: #{prompt_user}" }.to_json
  end

  def embeddings(input:)
    raise 'not implemented yet due to missing API'
  end

  def self.ping!(_config)
    nil
  end
end

class Service::AI::Feature::SampleService < Service::AI::Feature
  def self.lookup_attributes(context_data, _locale)
    {
      identifier: "sample_service_#{context_data[:ticket].id}",
    }
  end

  def self.lookup_version(context_data, _locale)
    context_data[:ticket].updated_at.to_i
  end
end

RSpec.describe Service::AI::Feature do
  subject(:ai_service) { Service::AI::Feature::SampleService.new(context_data:) } # rubocop:disable Zammad/ForbidCallingServiceDirectly

  let(:context_data) { { ticket: create(:ticket) } }

  before do
    stub_const('Service::AI::Feature::PROMPT_PATH_STRING', Rails.root.join('test/data/ai/prompts/%{service}_%{type}.text.erb').to_s)
    setup_ai_provider 'sample_provider'
  end

  describe '#execute' do
    it 'check result' do
      result = ai_service.execute
      expect(result).not_to be_nil
    end

    context 'when AI response is a empty string' do
      it 'returns a result' do
        result = ai_service.execute
        expect(result).not_to be_nil
      end
    end

    describe 'connection health status' do
      it 'records a successful call on the connection' do
        expect { ai_service.execute }
          .to change { AI::ProviderConnection.find_by(name: 'default').status['state'] }
          .to('ok')
      end

      context 'when the provider call fails' do
        before do
          allow_any_instance_of(AI::Provider::SampleProvider)
            .to receive(:chat).and_raise(AI::Provider::ResponseError, 'Sample provider error')
        end

        it 'records the error on the connection', aggregate_failures: true do
          expect { ai_service.execute }.to raise_error(AI::Provider::ResponseError)

          expect(AI::ProviderConnection.find_by(name: 'default').status).to include(
            'state'   => 'error',
            'message' => 'Sample provider error',
          )
        end
      end
    end

    describe 'provider options' do
      it 'applies the feature routing options' do
        allow(AI::FeatureProvider).to receive(:options_for).and_return({ temperature: 0.2 })

        expect(ai_service.send(:provider).options).to include(temperature: 0.2)
      end

      it 'lets caller options win over the feature routing options' do
        allow(AI::FeatureProvider).to receive(:options_for).and_return({ model: 'routed-model' })
        service = Service::AI::Feature::SampleService.new(context_data:, additional_options: { model: 'caller-model' }) # rubocop:disable Zammad/ForbidCallingServiceDirectly

        expect(service.send(:provider).options).to include(model: 'caller-model')
      end

      it 'passes the service name to the provider' do
        expect(ai_service.send(:provider).options).to include(service_name: 'SampleService')
      end
    end

    describe 'analytics' do
      context 'when analytics is enabled' do
        before do
          allow(ai_service).to receive(:analytics?).and_return(true)
        end

        it 'saves an analytics run' do
          expect { ai_service.execute }
            .to change(AI::Analytics::Run, :count).by(1)
        end

        it 'saves payload' do
          ai_service.execute
          new_run = AI::Analytics::Run.last

          expect(new_run.payload).to eq(
            'prompt_system' => "system prompt\n",
            'prompt_user'   => "user prompt\n",
            'prompt_image'  => nil,
          )
        end

        context 'when service raises an error' do
          before do
            allow_any_instance_of(AI::Provider::SampleProvider)
              .to receive(:chat).and_raise(StandardError, 'Sample error')
          end

          it 'saves payload and an error message', aggregate_failures: true do
            expect { ai_service.execute }.to raise_error(StandardError, 'Sample error')

            new_run = AI::Analytics::Run.last

            expect(new_run).to have_attributes(
              payload: {
                'prompt_system' => "system prompt\n",
                'prompt_user'   => "user prompt\n",
                'prompt_image'  => nil,
              },
              error:   {
                'error_message' => 'Sample error',
                'error_class'   => 'StandardError',
              },
            )
          end
        end

        context 'when regeneration_of is provided' do
          subject(:ai_service) do
            Service::AI::Feature::SampleService # rubocop:disable Zammad/ForbidCallingServiceDirectly
              .new(context_data:, regeneration_of: original_run)
          end

          let(:original_run) { create(:ai_analytics_run) }

          it 'saves an analytics run with regeneration_of' do
            ai_service.execute
            new_run = AI::Analytics::Run.last
            expect(new_run.regeneration_of).to eq(original_run)
          end

          context 'when persistance strategy is stored_only' do
            subject(:ai_service) do
              Service::AI::Feature::SampleService # rubocop:disable Zammad/ForbidCallingServiceDirectly
                .new(context_data:, regeneration_of: original_run, persistence_strategy: :stored_only)
            end

            it 'does not regenerate' do
              expect { ai_service.execute }
                .not_to change(AI::Analytics::Run, :count)
            end
          end
        end
      end

      context 'when analytics not enabled' do
        before do
          allow(ai_service).to receive(:analytics?).and_return(false)
        end

        it 'saves an analytics run' do
          expect { ai_service.execute }
            .not_to change(AI::Analytics::Run, :count)
        end
      end
    end
  end
end
