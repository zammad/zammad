# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue5147ModifiedOperator, type: :db_migration do
  let(:core_workflow_1) { create(:core_workflow, condition_selected: { 'ticket.tree_select_749211'=>{ 'operator'=>'has changed' } }) }
  let(:core_workflow_2) { create(:core_workflow, condition_saved: { 'ticket.tree_select_749211'=>{ 'operator' => 'changed to', 'value' => [], 'value_completion' => '' } }) }
  let(:core_workflow_3) { create(:core_workflow, condition_selected: { 'ticket.tree_select_749211'=>{ 'operator' => 'is', 'value' => [], 'value_completion' => '' } }) }

  before do
    core_workflow_1
    core_workflow_2
    migrate
  end

  it 'does change the operator from has changed to just changed' do
    expect(core_workflow_1.reload.condition_selected['ticket.tree_select_749211']['operator']).to eq('just changed')
  end

  it 'does change the operator from has changed to to just changed to' do
    expect(core_workflow_2.reload.condition_saved['ticket.tree_select_749211']['operator']).to eq('just changed to')
  end

  it 'does not change the operator' do
    expect(core_workflow_3.reload.condition_selected['ticket.tree_select_749211']['operator']).to eq('is')
  end
end
