# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe RegexOperatorRenaming, type: :db_migration do
  context 'when time_accounting_selector needs to be updated' do
    before do
      Setting.set('time_accounting_selector', {
                    'condition' => {
                      'ticket.number' => { 'operator' => 'regex match',    'value' => 'test' },
                      'ticket.title'  => { 'operator' => 'regex mismatch', 'value' => 'test2' },
                    }
                  })

      migrate
    end

    it 'does migrate the selector' do
      expect(Setting.get('time_accounting_selector')).to eq({ 'condition' =>
                                                                             { 'ticket.number' => { 'operator' => 'matches regex', 'value' => 'test' },
                                                                               'ticket.title'  => { 'operator' => 'does not match regex', 'value' => 'test2' }, } })
    end
  end

  context 'when core workflows needs to be updated' do
    let!(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.title': {
                 operator: 'regex mismatch',
                 value:    [ '^dummy' ],
               },
               'ticket.dummy': {
                 operator: 'contains',
                 value:    %w[v1 v2],
               },
             },
             condition_saved:    {
               'ticket.title':  {
                 operator: 'regex match',
                 value:    [ '^dummy' ],
               },
               'ticket.dummy2': {
                 operator: 'contains',
                 value:    %w[v3 v4],
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

    it 'does not migrate the workflows that do not use regex operators' do
      expect { migrate }.to not_change(workflow_unchanged, :reload)
    end

    it 'does migrate the workflows', :aggregate_failures do
      migrate

      expect(workflow.reload.condition_selected).to eq({
                                                         'ticket.title' => { 'operator' => 'does not match regex', 'value' => ['^dummy'] },
                                                         'ticket.dummy' => { 'operator' => 'contains', 'value' => %w[v1 v2], },
                                                       })

      expect(workflow.reload.condition_saved).to eq({
                                                      'ticket.title'  => { 'operator' => 'matches regex', 'value' => ['^dummy'] },
                                                      'ticket.dummy2' => { 'operator' => 'contains', 'value' => %w[v3 v4], },
                                                    })
    end
  end
end
