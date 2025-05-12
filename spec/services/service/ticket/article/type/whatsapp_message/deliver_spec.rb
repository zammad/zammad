# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Article::Type::WhatsappMessage::Deliver do
  subject(:service) { described_class.new(article_id: article.id) }

  let(:article) { create(:whatsapp_article, :pending_delivery, **(try(:factory_options) || {})) }

  before do
    article
  end

  def expected_failure_article_note_data(error_message)
    {
      'content_type' => 'text/plain',
      'body'         => "Unable to send whatsapp message: #{error_message}",
      'internal'     => true,
      'sender_id'    => Ticket::Article::Sender.find_by(name: 'System').id,
      'type_id'      => Ticket::Article::Type.find_by(name: 'note').id,
      'preferences'  => {
        'delivery_article_id_related' => article.id,
        'delivery_message'            => true,
      },
    }
  end

  describe '#execute' do
    shared_examples 'permanent delivery failure', :aggregate_failures do
      it 'raise error and adds a delivery failure note (article) to the ticket' do
        expect do
          begin
            service.execute
          rescue Service::Ticket::Article::Type::PermanentDeliveryError => e
            expect(Ticket::Article.last.attributes).to include(expected_failure_article_note_data(e.message))

            # Re-raise the error to confirm that it's the expected error
            raise e
          end
        end.to raise_error(Service::Ticket::Article::Type::PermanentDeliveryError)
      end

      it 'sets the appropriate delivery status attributes' do
        begin
          service.execute
        rescue Service::Ticket::Article::Type::PermanentDeliveryError => e
          expect(article.reload.preferences[:delivery_status]).to eq('fail')
          expect(article.reload.preferences[:delivery_status_date]).to be_an_instance_of(ActiveSupport::TimeWithZone)
          expect(article.reload.preferences[:delivery_status_message]).to eq(e.message)
        end
      end
    end

    context 'with not existing ticket channel' do
      before do
        Channel.last.destroy!
      end

      it_behaves_like 'permanent delivery failure'
    end

    context 'with wrong ticket channel' do
      let(:article) { create(:twitter_article) }

      it_behaves_like 'permanent delivery failure'
    end

    context 'with existing ticket channel' do
      context 'with missing recipient phone number in ticket prefernces' do
        before do
          ticket = Ticket.find(article.ticket_id)
          ticket.preferences['whatsapp']['from']['phone_number'] = nil
          ticket.save!
        end

        it_behaves_like 'permanent delivery failure'
      end

      context 'with all needed meta data' do
        let(:message_id) { "wamid.#{Faker::Crypto.unique.sha1}==" }
        let(:internal_response) do
          Struct.new(:messages).new([Struct.new(:id).new(message_id)])
        end

        shared_examples 'successful delivery' do
          it 'returns article with delivered message_id', :aggregate_failures do
            article = service.execute

            expect(article.message_id).to eq(message_id)
            expect(article.preferences[:delivery_status]).to eq('success')
            expect(article.preferences[:delivery_status_date]).to be_present
            expect(article.preferences[:delivery_status_message]).to be_nil
          end
        end

        context 'with text message' do
          before do
            allow_any_instance_of(WhatsappSdk::Api::Messages).to receive(:send_text).and_return(internal_response)
          end

          it_behaves_like 'successful delivery'
        end

        context 'with an media whatsapp article (image)' do
          let(:media_id)                { Faker::Number.unique.number(digits: 15) }
          let(:internal_response_media) { Struct.new(:id).new(media_id) }
          let(:internal_response)       { Struct.new(:messages).new([Struct.new(:id).new(message_id)]) }

          before do
            create(
              :store,
              object:      'Ticket::Article',
              o_id:        article.id,
              data:        'fake',
              filename:    'attached_image.jpg',
              preferences: {
                'Content-Type' => 'image/jpeg',
                'Mime-Type'    => 'image/jpeg',
              }
            )

            allow_any_instance_of(WhatsappSdk::Api::Medias).to receive(:upload).and_return(internal_response_media)
            allow_any_instance_of(WhatsappSdk::Api::Messages).to receive(:send_image).and_return(internal_response)
          end

          it_behaves_like 'successful delivery'
        end

        context 'with unsuccessful response' do
          before do
            allow_any_instance_of(WhatsappSdk::Api::Messages).to receive(:send_text).and_return(internal_response)
          end

          let(:internal_response) do
            Struct
              .new(:data,
                   :error,
                   :raw_response)
              .new(nil,
                   Struct.new(:message).new('error message'),
                   '{}')
          end

          it 'raises an temporary delivery error and increased retry count', :aggregate_failures do
            expect { service.execute }.to raise_error(Service::Ticket::Article::Type::TemporaryDeliveryError)

            expect(article.ticket.reload.articles.count).to eq(1)
            expect(article.reload.preferences[:delivery_status]).to eq('fail')
            expect(article.reload.preferences[:delivery_status_date]).to be_an_instance_of(ActiveSupport::TimeWithZone)
            expect(article.reload.preferences[:delivery_retry]).to eq(1)
          end

          context 'with already 3 delivery retries' do
            let(:factory_options) { { preferences: { delivery_retry: 3 } } }

            it 'raises an temporary delivery error (increased retry count and create failure article note)', :aggregate_failures do
              expect do
                begin
                  service.execute
                rescue Service::Ticket::Article::Type::TemporaryDeliveryError => e
                  expect(Ticket::Article.last.attributes).to include(expected_failure_article_note_data(e.message))

                  expect(article.reload.preferences[:delivery_status]).to eq('fail')
                  expect(article.reload.preferences[:delivery_status_date]).to be_an_instance_of(ActiveSupport::TimeWithZone)
                  expect(article.reload.preferences[:delivery_status_message]).to eq(e.message)
                  expect(article.reload.preferences[:delivery_retry]).to eq(4)

                  # Re-raise the error to confirm that it's the expected error
                  raise e
                end
              end.to raise_error(Service::Ticket::Article::Type::TemporaryDeliveryError)
            end
          end
        end
      end
    end
  end
end
