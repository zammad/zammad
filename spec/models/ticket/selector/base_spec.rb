# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Selector::Base, searchindex: true do
  let(:agent)    { create(:agent, groups: [Group.first]) }
  let(:ticket_1) { create(:ticket, title: 'bli', group: Group.first) }
  let(:ticket_2) { create(:ticket, title: 'bla', group: Group.first) }
  let(:ticket_3) { create(:ticket, title: 'blub', group: Group.first) }

  before do
    Ticket.destroy_all
    ticket_1 && ticket_2 && ticket_3
    searchindex_model_reload([Ticket])
  end

  it 'does support AND conditions', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'b',
        },
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'l',
        },
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'b',
        },
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(3)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(3)
  end

  it 'does support NOT conditions', :aggregate_failures do
    condition = {
      operator:   'NOT',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'b',
        },
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'l',
        },
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'b',
        },
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(0)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(0)
  end

  it 'does support OR conditions', :aggregate_failures do
    condition = {
      operator:   'OR',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'bli',
        },
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'bla',
        },
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'blub',
        },
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(3)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(3)
  end

  it 'does support OR conditions (one missing)', :aggregate_failures do
    condition = {
      operator:   'OR',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'xxx',
        },
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'bla',
        },
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'blub',
        },
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(2)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(2)
  end

  it 'does support OR conditions (all missing)', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'bli',
        },
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'bla',
        },
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'blub',
        },
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(0)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(0)
  end

  it 'does support sub level conditions', :aggregate_failures do
    condition = {
      operator:   'OR',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'bli',
        },
        {
          operator:   'OR',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is',
              value:    'bla',
            },
            {
              name:     'ticket.title',
              operator: 'is',
              value:    'blub',
            },
          ],
        }
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(3)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(3)
  end

  it 'does support sub level conditions (one missing)', :aggregate_failures do
    condition = {
      operator:   'OR',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'bli',
        },
        {
          operator:   'OR',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is',
              value:    'xxx',
            },
            {
              name:     'ticket.title',
              operator: 'is',
              value:    'blub',
            },
          ],
        }
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(2)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(2)
  end

  it 'does support sub level conditions (all missing)', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'bli',
        },
        {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is',
              value:    'bla',
            },
            {
              name:     'ticket.title',
              operator: 'is',
              value:    'blub',
            },
          ],
        }
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(0)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(0)
  end

  it 'does return all 3 results on empty condition', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: []
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(3)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(3)
  end

  it 'does return all 3 results on empty sub condition', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'b',
        },
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'l',
        },
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'b',
        },
        {
          operator:   'AND',
          conditions: [
          ],
        }
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(3)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(3)
  end

  it 'does return all 3 results on empty sub sub condition', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'b',
        },
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'l',
        },
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'b',
        },
        {
          operator:   'AND',
          conditions: [
            {
              operator:   'AND',
              conditions: [
              ],
            }
          ],
        }
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(3)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(3)
  end
end
