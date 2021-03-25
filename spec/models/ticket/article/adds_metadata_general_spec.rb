require 'rails_helper'

RSpec.describe Ticket::Article::AddsMetadataGeneral, current_user_id: -> { agent.id } do
  let(:agent) { create(:agent) }

  context 'when customer is agent' do
    let(:customer) { create(:agent) }

    it 'show customer agent details in from field' do
      ticket  = create(:ticket, customer_id: customer.id)
      article = create(:ticket_article, :inbound_phone, ticket: ticket)

      expect(article.from).to include customer.email
    end
  end
end
