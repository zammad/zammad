# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

class AI::Provider::SampleProvider < AI::Provider
  def chat(prompt_system:, prompt_user:)
    { response: "System: #{prompt_system}\nUser: #{prompt_user}" }.to_json
  end

  def embeddings(input:)
    raise 'not implemented yet due to missing API'
  end

  def self.ping!(_config)
    nil
  end
end

class AI::Service::SampleService < AI::Service
  def self.lookup_attributes(context_data, _locale)
    {
      identifier: "sample_service_#{context_data[:ticket].id}",
    }
  end

  def self.lookup_version(context_data, _locale)
    context_data[:ticket].updated_at.to_i
  end
end

RSpec.describe AI::Service do
  subject(:ai_service) { AI::Service::SampleService.new(current_user:, context_data:) }

  let(:context_data)   { { ticket: create(:ticket) } }
  let(:current_user)   { create(:user) }

  before do
    stub_const('AI::Service::PROMPT_PATH_STRING', Rails.root.join('test/data/ai/prompts/%{service}_%{type}.text.erb').to_s)
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
            AI::Service::SampleService
              .new(current_user:, context_data:, regeneration_of: original_run)
          end

          let(:original_run) { create(:ai_analytics_run) }

          it 'saves an analytics run with regeneration_of' do
            ai_service.execute
            new_run = AI::Analytics::Run.last
            expect(new_run.regeneration_of).to eq(original_run)
          end

          context 'when persistance strategy is stored_only' do
            subject(:ai_service) do
              AI::Service::SampleService
                .new(current_user:, context_data:, regeneration_of: original_run, persistence_strategy: :stored_only)
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
