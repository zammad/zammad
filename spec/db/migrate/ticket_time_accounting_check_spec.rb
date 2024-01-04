# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketTimeAccountingCheck, type: :db_migration do
  let(:ldap_user) { create(:user, source: 'Ldap') }

  before do
    Setting.set('time_accounting_selector', { 'condition' =>
                                                             { 'ticket.number'   => { 'operator' => 'contains', 'value' => 'test' },
                                                               'ticket.title'    => { 'operator' => 'contains not', 'value' => 'test2' },
                                                               'ticket.owner_id' => { 'operator' => 'is', 'pre_condition' => 'not_set', 'value' => [], 'value_completion' => '' } } })

    migrate
  end

  it 'does migrate the selector' do
    expect(Setting.get('time_accounting_selector')).to eq({ 'condition' =>
                                                                           { 'ticket.number'   => { 'operator' => 'regex match', 'value' => 'test' },
                                                                             'ticket.title'    => { 'operator' => 'regex mismatch', 'value' => 'test2' },
                                                                             'ticket.owner_id' => { 'operator' => 'not set' } } })
  end
end
