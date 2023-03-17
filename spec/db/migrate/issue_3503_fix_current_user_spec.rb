# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3503FixCurrentUser, type: :db_migration do
  let!(:job) { create(:job) }
  let!(:sla) { create(:sla) }

  before do
    condition = { 'ticket.organization_id' => { 'operator' => 'is', 'pre_condition' => 'current_user.organization_id', 'value' => '' }, 'ticket.action' => { 'operator' => 'is', 'value' => 'create' } }
    job.update_column(:condition, condition)
    sla.update_column(:condition, condition)
  end

  it 'removes current user condition from Jobs' do
    expect { migrate }.to change { job.reload.condition }.to({ 'ticket.action'=>{ 'operator' => 'is', 'value' => 'create' } })
  end

  it 'removes current user condition from Slas' do
    expect { migrate }.to change { sla.reload.condition }.to({ 'ticket.action'=>{ 'operator' => 'is', 'value' => 'create' } })
  end
end
