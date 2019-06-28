require 'rails_helper'

RSpec.describe 'Ticket Escalation', type: :request do

  let!(:agent_user) do
    create(:agent_user, groups: Group.all)
  end
  let!(:customer_user) do
    create(:customer_user)
  end
  let!(:calendar) do
    create(
      :calendar,
      name:           'Escalation Test',
      timezone:       'Europe/Berlin',
      business_hours: {
        mon: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        tue: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        wed: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        thu: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        fri: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        sat: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        sun: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
      },
      default:        true,
      ical_url:       nil,
    )
  end
  let!(:sla) do
    create(
      :sla,
      name:                'test sla 1',
      condition:           {
        'ticket.title' => {
          operator: 'contains',
          value:    'some value 123',
        },
      },
      first_response_time: 60,
      update_time:         180,
      solution_time:       240,
      calendar:            calendar,
    )
  end
  let!(:mail_group) do
    create(:group, email_address: create(:email_address) )
  end

  describe 'request handling' do

    it 'does escalate by ticket created via web' do
      params = {
        title:   'some value 123',
        group:   mail_group.name,
        article: {
          body: 'some test 123',
        },
      }

      authenticated_as(customer_user)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('some value 123')
      expect(json_response['updated_by_id']).to eq(customer_user.id)
      expect(json_response['created_by_id']).to eq(customer_user.id)

      ticket_p = Ticket.find(json_response['id'])

      expect(json_response['escalation_at'].sub(/.\d\d\dZ$/, 'Z')).to eq(ticket_p['escalation_at'].iso8601)
      expect(json_response['first_response_escalation_at'].sub(/.\d\d\dZ$/, 'Z')).to eq(ticket_p['first_response_escalation_at'].iso8601)
      expect(json_response['update_escalation_at'].sub(/.\d\d\dZ$/, 'Z')).to eq(ticket_p['update_escalation_at'].iso8601)
      expect(json_response['close_escalation_at'].sub(/.\d\d\dZ$/, 'Z')).to eq(ticket_p['close_escalation_at'].iso8601)

      expect(ticket_p.escalation_at).to be_truthy
      expect(ticket_p.first_response_escalation_at.to_i).to be_within(90.seconds).of((ticket_p.created_at + 1.hour).to_i)
      expect(ticket_p.update_escalation_at.to_i).to be_within(90.seconds).of((ticket_p.created_at + 3.hours).to_i)
      expect(ticket_p.close_escalation_at.to_i).to be_within(90.seconds).of((ticket_p.created_at + 4.hours).to_i)
      expect(ticket_p.escalation_at.to_i).to be_within(90.seconds).of((ticket_p.created_at + 1.hour).to_i)
    end

    it 'does escalate by ticket got created via email - reply by agent via web' do

      email = "From: Bob Smith <customer@example.com>
To: #{mail_group.email_address.email}
Subject: some value 123

Some Text"

      ticket_p, _article_p, user_p, _mail = Channel::EmailParser.new.process({}, email)
      ticket_p.reload
      expect(ticket_p.escalation_at).to be_truthy
      expect(ticket_p.first_response_escalation_at.to_i).to be_within(90.seconds).of((ticket_p.created_at + 1.hour).to_i)
      expect(ticket_p.update_escalation_at.to_i).to be_within(90.seconds).of((ticket_p.created_at + 3.hours).to_i)
      expect(ticket_p.close_escalation_at.to_i).to be_within(90.seconds).of((ticket_p.created_at + 4.hours).to_i)
      expect(ticket_p.escalation_at.to_i).to be_within(90.seconds).of((ticket_p.created_at + 1.hour).to_i)

      travel 3.hours

      params = {
        title:   'some value 123 - update',
        article: {
          body: 'some test 123',
          type: 'email',
          to:   'customer@example.com',
        },
      }
      authenticated_as(agent_user)
      put "/api/v1/tickets/#{ticket_p.id}", params: params, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'open').id)
      expect(json_response['title']).to eq('some value 123 - update')
      expect(json_response['updated_by_id']).to eq(agent_user.id)
      expect(json_response['created_by_id']).to eq(user_p.id)

      ticket_p.reload
      expect(json_response['escalation_at'].sub(/.\d\d\dZ$/, 'Z')).to eq(ticket_p['escalation_at'].iso8601)
      expect(json_response['first_response_escalation_at'].sub(/.\d\d\dZ$/, 'Z')).to eq(ticket_p['first_response_escalation_at'].iso8601)
      expect(json_response['update_escalation_at'].sub(/.\d\d\dZ$/, 'Z')).to eq(ticket_p['update_escalation_at'].iso8601)
      expect(json_response['close_escalation_at'].sub(/.\d\d\dZ$/, 'Z')).to eq(ticket_p['close_escalation_at'].iso8601)

      expect(ticket_p.first_response_escalation_at.to_i).to be_within(90.seconds).of((ticket_p.created_at + 1.hour).to_i)
      expect(ticket_p.update_escalation_at.to_i).to be_within(90.seconds).of((ticket_p.last_contact_agent_at + 3.hours).to_i)
      expect(ticket_p.close_escalation_at.to_i).to be_within(90.seconds).of((ticket_p.created_at + 4.hours).to_i)
      expect(ticket_p.escalation_at.to_i).to be_within(90.seconds).of((ticket_p.created_at + 4.hours).to_i)
    end
  end
end
