# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::AIAssistance::CreateKnowledgeBaseAnswer do
  subject(:service) do
    described_class.new(
      ticket:            ticket,
      current_user:      user,
      knowledge_base_id: knowledge_base_id
    )
  end

  let(:ticket) { create(:ticket) }
  let(:user)   { create(:admin) }

  let(:knowledge_base_id)       { knowledge_base.id }
  let(:knowledge_base)          { create(:knowledge_base) }
  let(:knowledge_base_category) { create(:knowledge_base_category, knowledge_base:) }
  let(:kb_locale)               { knowledge_base.kb_locales.find_by(primary: true) || knowledge_base.kb_locales.first }

  describe '#execute' do
    context 'when ai result contains content' do
      let(:service_result) do
        AI::Service::Result.new(
          content: {
            'title' => 'Generated draft title'
          }
        )
      end

      let(:request_service) do
        instance_double(
          Service::Ticket::AIAssistance::GenerateKnowledgeBaseAnswerContent,
          execute: service_result
        )
      end

      let(:kb_answer)             { create(:knowledge_base_answer, category: knowledge_base_category) }
      let(:create_answer_service) { instance_double(Service::KnowledgeBase::CreateAnswerFromAIResult, execute: kb_answer) }

      before do
        knowledge_base_category
        allow(Service::Ticket::AIAssistance::GenerateKnowledgeBaseAnswerContent).to receive(:new).and_return(request_service)
        allow(Service::KnowledgeBase::CreateAnswerFromAIResult).to receive(:new).and_return(create_answer_service)
      end

      it 'creates a knowledge base answer' do
        service.execute

        expect(Service::KnowledgeBase::CreateAnswerFromAIResult)
          .to have_received(:new)
          .with(
            ai_result:       service_result.content,
            knowledge_base:,
            kb_locale:,
            current_user_id: user.id
          )
      end

      it 'links the created answer to the ticket' do
        service.execute

        translation = kb_answer.translations.first
        link = Link.find_by(
          link_object_source_value: translation.id,
          link_object_target_value: ticket.id,
        )

        expect(link).to be_present
      end

      it 'creates a notification for the created answer', :aggregate_failures do
        service.execute

        notification = OnlineNotification.last

        expect(notification.object.name).to eq('KnowledgeBase::Answer::Translation')
        expect(notification.o_id).to eq(kb_answer.translations.first.id)
      end

      it 'passes default knowledge base locale to ai request service' do
        expected_system_locale = Locale.find_or_create_by!(locale: 'en-us') do |locale|
          locale.name = 'English'
        end
        kb_locale.update!(system_locale: expected_system_locale)

        service.execute

        expect(Service::Ticket::AIAssistance::GenerateKnowledgeBaseAnswerContent)
          .to have_received(:new)
          .with(hash_including(
                  locale:       expected_system_locale.locale,
                  ticket:,
                  current_user: user
                ))
      end

      context 'when user cannot edit all categories' do
        let(:user) { create(:admin_only) }
        let(:restricted_category) { create(:knowledge_base_category, knowledge_base:) }

        before do
          restricted_category

          KnowledgeBase::PermissionsUpdate
            .new(restricted_category)
            .update! user.roles.first => 'reader'
        end

        it 'passes only editable categories to the ai request service' do
          service.execute

          expect(Service::Ticket::AIAssistance::GenerateKnowledgeBaseAnswerContent)
            .to have_received(:new)
            .with(hash_including(
                    category_options: contain_exactly(
                      {
                        value: knowledge_base_category.id,
                        label: knowledge_base_category.translation&.title
                      }
                    )
                  ))
        end
      end

      context 'when user has no editable categories' do
        let(:user) { create(:admin_only) }

        before do
          KnowledgeBase::PermissionsUpdate
            .new(knowledge_base_category)
            .update! user.roles.first => 'reader'
        end

        it 'raises an error' do
          expect { service.execute }.to raise_error(Exceptions::UnprocessableEntity, 'No editable knowledge base categories available.')
        end
      end
    end

    context 'when ai result content is blank' do
      let(:service_result) { AI::Service::Result.new(content: nil) }
      let(:request_service) do
        instance_double(
          Service::Ticket::AIAssistance::GenerateKnowledgeBaseAnswerContent,
          execute: service_result
        )
      end

      before do
        knowledge_base_category
        allow(Service::Ticket::AIAssistance::GenerateKnowledgeBaseAnswerContent).to receive(:new).and_return(request_service)
        allow(Service::KnowledgeBase::CreateAnswerFromAIResult).to receive(:new)
      end

      it 'raises an error' do
        expect { service.execute }.to raise_error(Exceptions::UnprocessableEntity, 'Knowledge base draft could not be generated.')
      end

      it 'does not create a knowledge base answer', :aggregate_failures do
        expect { service.execute }.to raise_error(Exceptions::UnprocessableEntity, 'Knowledge base draft could not be generated.')

        expect(Service::KnowledgeBase::CreateAnswerFromAIResult).not_to have_received(:new)
      end
    end

    context 'when knowledge base does not exist' do
      let(:knowledge_base_id) { -1 }

      it 'raises an error' do
        expect { service.execute }.to raise_error(Exceptions::UnprocessableEntity, 'Knowledge base is unavailable or not properly configured.')
      end
    end

    context 'when knowledge base has no categories' do
      let(:knowledge_base_without_categories) { create(:knowledge_base) }
      let(:knowledge_base_id)                 { knowledge_base_without_categories.id }

      it 'raises an error' do
        expect { service.execute }.to raise_error(Exceptions::UnprocessableEntity, 'Knowledge base is unavailable or not properly configured.')
      end
    end
  end
end
