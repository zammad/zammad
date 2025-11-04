# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Selector::Base, searchindex: true do
  let(:default_organization) { create(:organization) }
  let(:agent)                { create(:agent, groups: [Group.first]) }
  let(:agent_owner)          { create(:agent, groups: [Group.first], organization: default_organization) }
  let(:default_customer)     { create(:customer, organization: default_organization) }
  let(:ticket_1)             { create(:ticket, title: 'bli', group: Group.first, owner: agent_owner, customer: default_customer) }
  let(:ticket_2)             { create(:ticket, title: 'bla', group: Group.first, owner: agent_owner, customer: default_customer) }
  let(:ticket_3)             { create(:ticket, title: 'blub', group: Group.first, owner: agent_owner, customer: default_customer) }

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

  it 'does support owner_id is not_set pre_condition', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: [
        {
          pre_condition: 'not_set',
          name:          'ticket.owner_id',
          operator:      'is',
          value:         [],
        },
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(0)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(0)
  end

  it 'does support owner_id is not not_set pre_condition', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: [
        {
          pre_condition: 'not_set',
          name:          'ticket.owner_id',
          operator:      'is not',
          value:         [],
        },
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(3)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(3)
  end

  it 'does support owner is current_user.id pre_condition', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: [
        {
          pre_condition: 'current_user.id',
          name:          'ticket.owner_id',
          operator:      'is',
          value:         [],
        },
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent_owner })
    expect(count).to eq(3)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent_owner })
    expect(result[:count]).to eq(3)
  end

  it 'does support owner is current_user.id pre_condition but user has none', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: [
        {
          pre_condition: 'current_user.id',
          name:          'ticket.owner_id',
          operator:      'is',
          value:         [],
        },
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(0)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(0)
  end

  it 'does support owner is current_user.organization_id pre_condition', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: [
        {
          pre_condition: 'current_user.organization_id',
          name:          'ticket.organization_id',
          operator:      'is',
          value:         [],
        },
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent_owner })
    expect(count).to eq(3)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent_owner })
    expect(result[:count]).to eq(3)
  end

  it 'does support owner is current_user.organization_id pre_condition but user has none', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: [
        {
          pre_condition: 'current_user.organization_id',
          name:          'ticket.organization_id',
          operator:      'is',
          value:         [],
        },
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(0)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(0)
  end

  describe 'Report profile terminates with error if today is used as timestamp for condition #4901' do
    before do
      ticket_1.update(created_at: 1.day.ago)
      searchindex_model_reload([Ticket])
    end

    it 'does support today operator', :aggregate_failures do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'ticket.created_at',
            operator: 'today',
          },
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(2)

      result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
      expect(result[:count]).to eq(2)
    end
  end

  describe 'Trigger do not allow "Multi-Tree-Select" Fields on Organization and User Level as If Condition #4504', db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:organization) { create(:organization, field_name => ['Incident', 'Incident::Hardware']) }
    let(:customer)     { create(:customer, organization: organization, field_name => ['Incident', 'Incident::Hardware']) }
    let(:ticket)       { create(:ticket, title: 'bli', group: Group.first, customer: customer, field_name => ['Incident', 'Incident::Hardware']) }

    def check_condition(attribute)
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     attribute.to_s,
            operator: 'contains all',
            value:    ['Incident', 'Incident::Hardware'],
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(1)

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(1)
    end

    before do
      create(:object_manager_attribute_multi_tree_select, object_name: 'Ticket', name: field_name)
      create(:object_manager_attribute_multi_tree_select, object_name: 'User', name: field_name)
      create(:object_manager_attribute_multi_tree_select, object_name: 'Organization', name: field_name)
      ObjectManager::Attribute.migration_execute
      ticket
      searchindex_model_reload([Ticket, User, Organization])
    end

    it 'does support contains one for all objects' do # rubocop:disable RSpec/NoExpectationExample
      check_condition("ticket.#{field_name}")
      check_condition("customer.#{field_name}")
      check_condition("organization.#{field_name}")
    end
  end

  describe 'Reporting profiles do not work with multi tree select #4546' do
    context 'when value is a string' do
      before do
        create(:tag, tag_item: create(:'tag/item', name: 'AAA'), o: ticket_1)
        create(:tag, tag_item: create(:'tag/item', name: 'BBB'), o: ticket_1)
        searchindex_model_reload([Ticket])
      end

      it 'does return ticket by contains all string value', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains all',
              value:    'AAA, BBB',
            }
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(1)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(1)
      end
    end

    context 'when value is an array', db_strategy: :reset do
      let(:field_name) { SecureRandom.uuid }

      before do
        create(:object_manager_attribute_multi_tree_select, name: field_name)
        ObjectManager::Attribute.migration_execute
        ticket_1.reload.update(field_name => ['Incident', 'Incident::Hardware'])
        searchindex_model_reload([Ticket])
      end

      it 'does return ticket by contains all array value', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     "ticket.#{field_name}",
              operator: 'contains all',
              value:    ['Incident', 'Incident::Hardware'],
            }
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(1)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(1)
      end
    end
  end

  describe 'Report profiles: Problem with some conditions (starts with, ends with, is any, is none) #4798' do
    context 'when operator is any of' do
      it 'does match', :aggregate_failures do
        condition = {
          operator:   'OR',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is any of',
              value:    %w[bli bla],
            },
            {
              name:     'ticket.title',
              operator: 'is any of',
              value:    ['blub'],
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(3)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(3)
      end

      it 'does not match', :aggregate_failures do
        condition = {
          operator:   'OR',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is any of',
              value:    %w[blix blax],
            },
            {
              name:     'ticket.title',
              operator: 'is any of',
              value:    ['blubx'],
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(0)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(0)
      end
    end

    context 'when operator is none of' do
      it 'does match', :aggregate_failures do
        condition = {
          operator:   'OR',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is none of',
              value:    %w[blix blax],
            },
            {
              name:     'ticket.title',
              operator: 'is none of',
              value:    ['blubx'],
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(3)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(3)
      end

      it 'does not match', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is none of',
              value:    %w[bli bla],
            },
            {
              name:     'ticket.title',
              operator: 'is none of',
              value:    ['blub'],
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(0)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(0)
      end
    end

    context 'when operator starts with one of' do
      it 'does match', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'starts with one of',
              value:    ['bl'],
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(3)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(3)
      end

      it 'does not match', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'starts with one of',
              value:    ['aaa'],
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(0)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(0)
      end
    end

    context 'when operator ends with one of' do
      it 'does match', :aggregate_failures do
        condition = {
          operator:   'OR',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'ends with one of',
              value:    %w[li la],
            },
            {
              name:     'ticket.title',
              operator: 'ends with one of',
              value:    ['ub'],
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(3)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(3)
      end

      it 'does not match', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'ends with one of',
              value:    ['ubx'],
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(0)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(0)
      end
    end
  end

  describe 'Tags' do
    let(:ta) { create(:'tag/item', name: 'a') }
    let(:tb) { create(:'tag/item', name: 'b') }
    let(:tc) { create(:'tag/item', name: 'c') }
    let(:td) { create(:'tag/item', name: 'd') }

    let(:ticket_a) do
      create(:ticket, group: Group.first).tap do |ticket|
        create(:tag, o: ticket, tag_item: ta)
      end
    end
    let(:ticket_a_b) do
      create(:ticket, group: Group.first).tap do |ticket|
        create(:tag, o: ticket, tag_item: ta)
        create(:tag, o: ticket, tag_item: tb)
      end
    end
    let(:ticket_none) { create(:ticket, group: Group.first) }

    before do
      Ticket.destroy_all
      ta && tb && tc && td
      ticket_a && ticket_a_b && ticket_none
      searchindex_model_reload([Ticket])
    end

    describe 'contains all' do
      it 'checks tags a = 2', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains all',
              value:    'a',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(2)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(2)
      end

      it 'checks tags a, b = 1', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains all',
              value:    'a,b',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(1)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(1)
      end

      it 'checks tags a, c = 0', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains all',
              value:    'a,c',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(0)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(0)
      end

      it 'checks tags a, b, c = 0', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains all',
              value:    'a,b,c',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(0)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(0)
      end

      it 'checks tags c, d = 0', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains all',
              value:    'c,d',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(0)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(0)
      end

      it 'checks tags d = 0', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains all',
              value:    'd',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(0)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(0)
      end
    end

    describe 'contains one' do
      it 'checks tags a = 2', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains one',
              value:    'a',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(2)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(2)
      end

      it 'checks tags a, b = 2', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains one',
              value:    'a,b',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(2)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(2)
      end

      it 'checks tags a, c = 2', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains one',
              value:    'a,c',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(2)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(2)
      end

      it 'checks tags a, b, c = 2', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains one',
              value:    'a,b,c',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(2)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(2)
      end

      it 'checks tags c, d = 0', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains one',
              value:    'c,d',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(0)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(0)
      end

      it 'checks tags d = 0', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains one',
              value:    'd',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(0)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(0)
      end
    end

    describe 'contains all not' do
      it 'checks tags a = 1', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains all not',
              value:    'a',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(1)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(1)
      end

      it 'checks tags a, b = 2', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains all not',
              value:    'a,b',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(2)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(2)
      end

      it 'checks tags a, c = 3', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains all not',
              value:    'a,c',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(3)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(3)
      end

      it 'checks tags a, b, c = 3', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains all not',
              value:    'a,b,c',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(3)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(3)
      end

      it 'checks tags c, d = 3', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains all not',
              value:    'c,d',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(3)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(3)
      end

      it 'checks tags d = 3', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains all not',
              value:    'd',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(3)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(3)
      end
    end

    describe 'contains one not' do
      it 'checks tags a = 1', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains one not',
              value:    'a',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(1)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(1)
      end

      it 'checks tags a, b = 1', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains one not',
              value:    'a,b',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(1)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(1)
      end

      it 'checks tags a, c = 1', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains one not',
              value:    'a,c',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(1)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(1)
      end

      it 'checks tags a, b, c = 1', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains one not',
              value:    'a,b,c',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(1)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(1)
      end

      it 'checks tags c, d = 3', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains one not',
              value:    'c,d',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(3)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(3)
      end

      it 'checks tags d = 3', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains one not',
              value:    'd',
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(3)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(3)
      end
    end
  end

  describe 'Integer operators', db_strategy: :reset do
    let(:field_name) { SecureRandom.hex(8) }
    let(:ticket)     { create(:ticket, title: SecureRandom.uuid, group: Group.first, owner: agent_owner, customer: default_customer, field_name => 42) }

    before do
      create(:object_manager_attribute_integer, object_name: 'Ticket', name: field_name)
      ObjectManager::Attribute.migration_execute
      ticket
      searchindex_model_reload([Ticket])
    end

    describe 'when is less than' do
      it 'does match the ticket', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is',
              value:    ticket.title,
            },
            {
              name:     "ticket.#{field_name}",
              operator: 'is less than',
              value:    43,
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(1)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(1)
      end

      it 'does not match the ticket', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is',
              value:    ticket.title,
            },
            {
              name:     "ticket.#{field_name}",
              operator: 'is less than',
              value:    42,
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(0)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(0)
      end
    end

    describe 'when is less than or equal to' do
      it 'does match the ticket', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is',
              value:    ticket.title,
            },
            {
              name:     "ticket.#{field_name}",
              operator: 'is less than or equal to',
              value:    42,
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(1)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(1)
      end

      it 'does not match the ticket', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is',
              value:    ticket.title,
            },
            {
              name:     "ticket.#{field_name}",
              operator: 'is less than or equal to',
              value:    41,
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(0)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(0)
      end
    end

    describe 'when is greater than' do
      it 'does match the ticket', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is',
              value:    ticket.title,
            },
            {
              name:     "ticket.#{field_name}",
              operator: 'is greater than',
              value:    41,
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(1)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(1)
      end

      it 'does not match the ticket', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is',
              value:    ticket.title,
            },
            {
              name:     "ticket.#{field_name}",
              operator: 'is greater than',
              value:    42,
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(0)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(0)
      end
    end

    describe 'when is greater than or equal to' do
      it 'does match the ticket', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is',
              value:    ticket.title,
            },
            {
              name:     "ticket.#{field_name}",
              operator: 'is greater than or equal to',
              value:    42,
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(1)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(1)
      end

      it 'does not match the ticket', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is',
              value:    ticket.title,
            },
            {
              name:     "ticket.#{field_name}",
              operator: 'is greater than or equal to',
              value:    43,
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(0)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(0)
      end
    end
  end

  describe 'Report Profile with selector "starts with one of" on text objects results in "unknown operator" #5198' do
    before do
      ticket_1.update(title: "1111 #{ticket_1.title}")
      ticket_2.update(title: "1111 #{ticket_2.title}")
      ticket_3.update(title: "1111 #{ticket_3.title}")
      searchindex_model_reload([Ticket])
    end

    it 'does match', :aggregate_failures do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'ticket.title',
            operator: 'starts with one of',
            value:    ['111'],
          },
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(3)

      result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
      expect(result[:count]).to eq(3)
    end
  end

  # https://github.com/zammad/zammad/issues/5623
  describe 'selectors relying on .keyword suffix fails with long articles', :aggregate_failures do
    let(:term)        { 'ežiukas' }
    let(:short_text) { "#{Faker::Lorem.characters(number: 30)} #{term}" }
    let(:long_text)  { "#{term} #{Faker::Lorem.characters(number: 300)}" }

    context 'when item is Ticket' do
      let(:article_short) { create(:ticket_article, ticket: ticket_1, body: short_text) }
      let(:article_long)  { create(:ticket_article, ticket: ticket_2, body: long_text) }

      before do
        article_short && article_long
        searchindex_model_reload([Ticket])
      end

      it 'article body does match' do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'article.body',
              operator: 'contains',
              value:    term,
            },
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(2)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(2)
      end
    end

    context 'when item is Organization' do
      let(:organization_short) { create(:organization, note: short_text) }
      let(:organization_long)  { create(:organization, note: long_text) }

      before do
        organization_short && organization_long
        searchindex_model_reload([Organization])
      end

      it 'organization note does match' do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'organization.note',
              operator: 'contains',
              value:    term,
            },
          ]
        }

        count, = Organization.selectors(condition, { current_user: agent })
        expect(count).to eq(2)

        result = SearchIndexBackend.selectors('Organization', condition, { current_user: agent })
        expect(result[:count]).to eq(2)
      end
    end

    context 'when item is KB Answer' do
      let(:answer_short) { create(:knowledge_base_answer_translation_content, body: short_text).translation.answer }
      let(:answer_long) { create(:knowledge_base_answer_translation_content, body: long_text).translation.answer }

      before do
        answer_short && answer_long
        searchindex_model_reload([KnowledgeBase::Answer::Translation])
      end

      it 'answer content does match' do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'content.body',
              operator: 'contains',
              value:    term,
            },
          ]
        }

        count, = KnowledgeBase::Answer::Translation.selectors(condition, { current_user: agent })
        expect(count).to eq(2)

        result = SearchIndexBackend.selectors('KnowledgeBase::Answer::Translation', condition, { current_user: agent })
        expect(result[:count]).to eq(2)
      end
    end
  end

  # https://github.com/zammad/zammad/issues/5686
  describe 'text blob selectors fail with complex partial phrases', :aggregate_failures do
    let(:ticket)    { create(:ticket, title: 'This is a test ticket') }
    let(:article)   { create(:ticket_article, ticket: ticket, body: 'phrase: 1337') }
    let(:condition) do
      {
        operator:   'AND',
        conditions: [
          {
            name:     'article.body',
            operator: 'contains',
            value:    term,
          },
        ]
      }
    end

    before do
      article
      searchindex_model_reload([Ticket])
    end

    context 'when term is a full phrase' do
      let(:term) { 'phrase: 1337' }

      it 'does match' do
        count, = Ticket.selectors(condition)
        expect(count).to eq(1)

        result = SearchIndexBackend.selectors('Ticket', condition)
        expect(result[:count]).to eq(1)
      end
    end

    context 'when term is a partial phrase' do
      let(:term) { 'phrase: 13' }

      it 'does match' do
        count, = Ticket.selectors(condition)
        expect(count).to eq(1)

        result = SearchIndexBackend.selectors('Ticket', condition)
        expect(result[:count]).to eq(1)
      end
    end
  end
end
