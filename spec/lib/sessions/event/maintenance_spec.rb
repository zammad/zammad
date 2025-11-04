# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Event::Maintenance do
  let(:user) { create(:admin) }

  before do
    allow(Sessions).to receive(:broadcast)
    allow(Gql::Subscriptions::PushMessages).to receive(:trigger)
  end

  context 'with admin.maintenance permission' do
    context 'with a message' do
      before do
        run_event({
                    'type'    => 'message',
                    'head'    => 'Maintenance',
                    'reload'  => true,
                    'message' => given_message,
                  })
      end

      shared_examples 'broadcasting messages' do
        it 'broadcasts the sanitized maintenance message' do
          expect(Sessions)
            .to have_received(:broadcast)
            .with(include('data' => include({
                                              'type'    => 'message',
                                              'reload'  => true,
                                              'message' => expected_message,
                                            })), 'public', any_args)
        end

        it 'sends the sanitized maintenance message to GraphQL subscriptions' do
          expect(Gql::Subscriptions::PushMessages)
            .to have_received(:trigger)
            .with({ title: 'Maintenance', text: expected_message })
        end
      end

      context 'when message is raw text' do
        let(:given_message) { 'Maintenance NOW!' }
        let(:expected_message) { 'Maintenance NOW!' }

        it_behaves_like 'broadcasting messages'
      end

      context 'when message is simple html' do
        let(:given_message) { 'Maintenance <b>NOW</b>!' }
        let(:expected_message) { 'Maintenance <b>NOW</b>!' }

        it_behaves_like 'broadcasting messages'
      end

      context 'when message is complex html' do
        let(:given_message) { 'Maintenance <b>NOW</b> <script>alert("XSS")</script>!' }
        let(:expected_message) { 'Maintenance <b>NOW</b> !' }

        it_behaves_like 'broadcasting messages'
      end

      context 'when message is empty' do
        let(:given_message) { nil }
        let(:expected_message) { '' }

        it_behaves_like 'broadcasting messages'
      end
    end

    context 'without a message' do
      before do
        run_event({
                    'type' => 'mode',
                    'on'   => true
                  })
      end

      it 'broadcasts the maintenance start/stop' do
        expect(Sessions)
          .to have_received(:broadcast)
          .with(include('data' => include({
                                            'type' => 'mode',
                                            'on'   => true,
                                          })), 'public', any_args)
      end

      it 'does not send anything to GraphQL subscriptions' do
        expect(Gql::Subscriptions::PushMessages)
          .not_to have_received(:trigger)
      end
    end
  end

  context 'without admin.maintenance permission' do
    let(:user) { create(:user) }

    before do
      run_event({
                  'type' => 'mode',
                  'on'   => true
                })
    end

    it 'does not run' do
      expect(Sessions)
        .not_to have_received(:broadcast).with(anything, 'public', any_args)
    end
  end

  def run_event(data)
    described_class.new(
      payload:   { 'data' => data },
      user_id:   user.id,
      client_id: 'sess_id',
      clients:   {},
      session:   { 'id' => user.id }
    ).run
  end
end
