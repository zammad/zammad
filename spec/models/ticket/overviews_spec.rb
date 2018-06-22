require 'rails_helper'

RSpec.describe Ticket::Overviews do

  describe '#index' do

    # https://github.com/zammad/zammad/issues/1769
    it 'does not return multiple results for a single ticket' do
      user           = create(:user)
      source_ticket  = create(:ticket, customer: user, created_by_id: user.id)
      source_ticket2 = create(:ticket, customer: user, created_by_id: user.id)

      # create some articles
      create(:ticket_article, ticket_id: source_ticket.id, from: 'asdf1@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket.id, from: 'asdf2@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket.id, from: 'asdf3@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket2.id, from: 'asdf3@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket2.id, from: 'asdf4@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket2.id, from: 'asdf5@blubselector.de', created_by_id: user.id)

      condition = {
        'article.from' => {
          operator: 'contains',
          value: 'blubselector.de',
        },
      }
      overview = create(:overview, condition: condition)

      result = Ticket::Overviews.index(user)
      result = result.select { |x| x[:overview][:name] == overview.name }

      expect(result.count).to be == 1
      expect(result[0][:count]).to be == 2
      expect(result[0][:tickets].count).to be == 2
    end
  end
end
