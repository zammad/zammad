# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TemplateMigration, type: :db_migration do
  let(:expected) do
    {
      'article.body'                  => 'twet 23123',
      'ticket.formSenderType'         => 'phone-in',
      'article.form_id'               => '187440978',
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
    }
  end

  let(:template) do

    # default format of 5.2 and earlier
    Template.create!(
      name:          'new',
      options:
                     {
                       'body'                   => 'twet 23123',
                       'formSenderType'         => 'phone-in',
                       'form_id'                => '187440978',
                       'title'                  => 'aaa',
                       'customer_id'            => '2',
                       'customer_id_completion' => 'Nicole Braun <nicole.braun@example.com>',
                       'cc'                     => 'somebody2@example.com',
                       'group_id'               => '1',
                       'owner_id'               => '11',
                       'state_id'               => '2',
                       'priority_id'            => '2',
                       'a1'                     => 'a',
                       'a2'                     => %w[a b],
                       'b1'                     => 'a::c',
                       'b2'                     => ['b'],
                       'b2_completion'          => '',
                       'category'               => 'a::aa',
                       'tags'                   => 'aa, bb'
                     },
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  before do
    template
  end

  context 'when migrating' do
    it 'update options' do
      migrate
      expect(template.reload.options).to eq(expected)
    end
  end

end
