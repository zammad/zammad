# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe InputFieldsOperatorRenaming, type: :db_migration do
  context 'when postmaster filters needs to be updated' do
    let!(:filter) do

      stub_const('PostmasterFilter::VALID_OPERATORS', [
                   'contains',
                   'contains not',
                   'is any of',
                   'is none of',
                   'starts with one of',
                   'ends with one of',

                   'is',
                   'is not',
                   'starts with',
                   'ends with',
                 ])

      create(:postmaster_filter,
             match: {
               'subject' => {
                 'operator' => 'is',
                 'value'    => 'dummy',
               },
               'to'      => {
                 'operator' => 'is not',
                 'value'    => 'no-reply@zammad.org',
               },
               'from'    => {
                 'operator' => 'starts with',
                 'value'    => 'a',
               },
               'cc'      => {
                 'operator' => 'ends with',
                 'value'    => 'a',
               },
               'body'    => {
                 'operator' => 'contains',
                 'value'    => 'Zammad',
               },
             })
    end

    it 'does migrate the postmaster filters' do
      migrate

      expect(filter.reload.match).to eq({
                                          'subject' => {
                                            'operator' => 'is any of',
                                            'value'    => 'dummy',
                                          },
                                          'to'      => {
                                            'operator' => 'is none of',
                                            'value'    => 'no-reply@zammad.org',
                                          },
                                          'from'    => {
                                            'operator' => 'starts with one of',
                                            'value'    => 'a',
                                          },
                                          'cc'      => {
                                            'operator' => 'ends with one of',
                                            'value'    => 'a',
                                          },
                                          'body'    => {
                                            'operator' => 'contains',
                                            'value'    => 'Zammad',
                                          },
                                        })
    end
  end

  context 'when core workflows needs to be updated' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.title': {
                 operator: 'is',
                 value:    'dummy',
               },
               'ticket.dummy': {
                 operator: 'contains',
                 value:    %w[v1 v2],
               },
             },
             condition_saved:    {
               'ticket.title':      {
                 operator: 'is not',
                 value:    'dummy',
               },
               'ticket.dummy2':     {
                 operator: 'contains',
                 value:    %w[v3 v4],
               },
               'ticket.treeselect': {
                 operator: 'is',
                 value:    'dummy',
               },
             })
    end

    let!(:workflow_unchanged) do
      create(:core_workflow,
             object:          'Ticket',
             condition_saved: {
               'custom.module': {
                 operator: 'match all modules',
                 value:    [ 'CoreWorkflow::Custom::TicketTimeAccountingCheck' ],
               }
             })
    end

    it 'does not migrate the workflows that do not use new input operators' do
      expect { migrate }.to not_change(workflow_unchanged, :reload)
    end

    it 'does migrate the workflows', :aggregate_failures do
      migrate

      expect(workflow.reload.condition_selected).to eq({
                                                         'ticket.title' => { 'operator' => 'is any of', 'value' => 'dummy' },
                                                         'ticket.dummy' => { 'operator' => 'contains', 'value' => %w[v1 v2], },
                                                       })

      expect(workflow.reload.condition_saved).to eq({
                                                      'ticket.title'      => { 'operator' => 'is none of', 'value' => 'dummy' },
                                                      'ticket.dummy2'     => { 'operator' => 'contains', 'value' => %w[v3 v4], },
                                                      'ticket.treeselect' => { 'operator' => 'is', 'value' => 'dummy' },
                                                    })
    end
  end
end
