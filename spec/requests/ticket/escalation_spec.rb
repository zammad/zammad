# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Escalation', type: :request do
  let(:sla_first_response) { 1.hour }
  let(:sla_update)         { 3.hours }
  let(:sla_close)          { 4.hours }

  let!(:mail_group) { create(:group, email_address: create(:email_address) ) }

  let(:calendar) { create(:calendar, :'24/7') }
  let(:sla) do
    create(:sla,
           calendar:            calendar,
           first_response_time: sla_first_response / 1.minute,
           update_time:         sla_update / 1.minute,
           solution_time:       sla_close / 1.minute)
  end

  define :json_equal_date do
    match do
      actual&.sub(%r{.\d\d\dZ$}, 'Z') == expected&.iso8601
    end
  end

  shared_examples 'response matching object' do
    %w[escalation_at first_response_escalation_at update_escalation_at close_escalation_at].each do |attribute|
      it "#{attribute} is representing the same time" do
        expect(json_response[attribute]).to json_equal_date ticket[attribute]
      end
    end
  end

  before do
    freeze_time
    sla
  end

  context 'when customer creates ticket via web', authenticated_as: :customer do
    subject(:ticket) { Ticket.find(json_response['id']) }

    let(:customer) { create(:customer) }

    before do
      params = {
        title:   'some value 123',
        group:   mail_group.name,
        article: {
          type_id: Ticket::Article::Type.find_by(name: 'web').id,
          body:    'some test 123',
        },
      }

      post '/api/v1/tickets', params: params, as: :json
    end

    it_behaves_like 'response matching object'

    it 'first response escalation in 1h' do
      expect(ticket.first_response_escalation_at).to eq 1.hour.from_now
    end

    it 'update_escalation in 3h' do
      expect(ticket.update_escalation_at).to eq 3.hours.from_now
    end

    it 'close escalation in 4h' do
      expect(ticket.close_escalation_at).to eq 4.hours.from_now
    end

    it 'next escalation is closest escalation' do
      expect(ticket.escalation_at).to eq 1.hour.from_now
    end
  end

  context 'when customer sends email' do
    subject(:ticket) { ticket_mail_in }

    before { ticket }

    it 'first response escalation in 1h' do
      expect(ticket.first_response_escalation_at).to eq 1.hour.from_now
    end

    it 'update_escalation in 3h' do
      expect(ticket.update_escalation_at).to eq 3.hours.from_now
    end

    it 'close escalation in 4h' do
      expect(ticket.close_escalation_at).to eq 4.hours.from_now
    end

    it 'next escalation is closest escalation' do
      expect(ticket.escalation_at).to eq 1.hour.from_now
    end
  end

  context 'when agent responds via web', authenticated_as: :agent do
    subject(:ticket) { ticket_mail_in }

    let(:agent) { create(:agent, groups: Group.all) }

    before { ticket && travel(3.hours) }

    it_behaves_like 'response matching object' do
      before { ticket_respond_web }
    end

    it 'clears first response escalation' do
      expect { ticket_respond_web }.to change(ticket, :first_response_escalation_at).to(nil)
    end

    it 'changes update escalation' do
      expect { ticket_respond_web }.to change(ticket, :update_escalation_at)
    end

    it 'update escalation is nil since agent responded' do
      ticket_respond_web
      expect(ticket.update_escalation_at).to be_nil
    end

    it 'does not change close escalation' do
      expect { ticket_respond_web }.not_to change(ticket, :close_escalation_at)
    end

    it 'change next escalation' do
      expect { ticket_respond_web }.to change(ticket, :escalation_at)
    end

    it 'next escalation is closest escalation which is close escalation' do
      ticket_respond_web
      expect(ticket.escalation_at).to eq 1.hour.from_now
    end

    def ticket_respond_web
      params = {
        title:   'some value 123 - update',
        article: {
          type_id: Ticket::Article::Type.find_by(name: 'email').id,
          body:    'some test 123',
          type:    'email',
          to:      'customer@example.com',
        },
      }

      put "/api/v1/tickets/#{ticket.id}", params: params, as: :json

      ticket.reload
    end
  end

  def ticket_mail_in
    email = <<~EMAIL
      From: Bob Smith <customer@example.com>
      To: #{mail_group.email_address.email}
      Subject: some value 123

      Some Text
    EMAIL

    ticket, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email)

    ticket
  end
end
