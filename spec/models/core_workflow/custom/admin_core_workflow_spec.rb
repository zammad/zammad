# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/core_workflow/base'

RSpec.describe CoreWorkflow::Custom::AdminCoreWorkflow, mariadb: true, type: :model do
  include_context 'with core workflow base'

  let(:payload) do
    base_payload.merge(
      'screen'     => 'edit',
      'class_name' => 'CoreWorkflow',
    )
  end

  it 'does not show screens for empty object' do
    expect(result[:restrict_values]['preferences::screen']).to eq([''])
  end

  it 'does not show invalid objects' do
    expect(result[:restrict_values]['object']).not_to include('CoreWorkflow')
  end

  describe 'on object Ticket' do
    let(:payload) do
      base_payload.merge(
        'screen'     => 'edit',
        'class_name' => 'CoreWorkflow',
        'params'     => { 'object' => 'Ticket' },
      )
    end

    it 'does show screen create_middle' do
      expect(result[:restrict_values]['preferences::screen']).to include('create_middle')
    end

    it 'does show screen edit' do
      expect(result[:restrict_values]['preferences::screen']).to include('edit')
    end
  end

  describe 'on saved object Ticket' do
    let(:workflow) { create(:core_workflow, object: 'Ticket') }
    let(:payload) do
      base_payload.merge(
        'screen'     => 'edit',
        'class_name' => 'CoreWorkflow',
        'params'     => { 'id' => workflow.id },
      )
    end

    it 'does show screen create_middle' do
      expect(result[:restrict_values]['preferences::screen']).to include('create_middle')
    end

    it 'does show screen edit' do
      expect(result[:restrict_values]['preferences::screen']).to include('edit')
    end
  end

  describe 'Error when selecting Group in core workflow #4868' do
    let(:payload) do
      base_payload.merge(
        'screen'     => 'edit',
        'class_name' => 'CoreWorkflow',
        'params'     => { 'object' => 'Group' },
      )
    end

    it 'does not throw error after object selection' do
      expect { result }.not_to raise_error
    end
  end
end
