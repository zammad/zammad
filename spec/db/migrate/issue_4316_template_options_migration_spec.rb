# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4316TemplateOptionsMigration, type: :db_migration do
  let(:expected) do
    {
      'article.body'          => { value: 'twet 23123' },
      'ticket.formSenderType' => { value: 'phone-in' },
      'ticket.title'          => { value: 'aaa' },
      'ticket.customer_id'    => { value: '2', value_completion: 'Nicole Braun <nicole.braun@example.com>' },
      'ticket.cc'             => { value: 'somebody2@example.com' },
      'ticket.group_id'       => { value: '1' },
      'ticket.owner_id'       => { value: '11' },
      'ticket.state_id'       => { value: '2' },
      'ticket.priority_id'    => { value: '2' },
      'ticket.a1'             => { value: 'a' },
      'ticket.a2'             => { value: %w[a b] },
      'ticket.b1'             => { value: 'a::c' },
      'ticket.b2'             => { value: ['b'], value_completion: '' },
      'ticket.category'       => { value: 'a::aa' },
      'ticket.tags'           => { value: 'aa, bb' },
    }
  end

  let(:template) do

    # Wrong format after initial migration from 5.2 to 5.3.
    Template.create!(
      name:          'new',
      options:
                     {
                       'article.body'                  => 'twet 23123',
                       'ticket.formSenderType'         => 'phone-in',
                       'ticket.title'                  => 'aaa',
                       'ticket.customer_id'            => '2',
                       'ticket.customer_id_completion' => 'Nicole Braun <nicole.braun@example.com>',
                       'ticket.cc'                     => 'somebody2@example.com',
                       'ticket.group_id'               => '1',
                       'ticket.owner_id'               => '11',
                       'ticket.state_id'               => '2',
                       'ticket.priority_id'            => '2',
                       'ticket.a1'                     => 'a',
                       'ticket.a2'                     => %w[a b],
                       'ticket.b1'                     => 'a::c',
                       'ticket.b2'                     => ['b'],
                       'ticket.b2_completion'          => '',
                       'ticket.category'               => 'a::aa',
                       'ticket.tags'                   => 'aa, bb'
                     },
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  before do
    template
  end

  context 'when migrating' do
    it 'update options to expected hash value (#4316)' do
      migrate
      expect(template.reload.options).to eq(expected.deep_stringify_keys)
    end
  end

end
