# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/core_workflow/base'

RSpec.describe CoreWorkflow::Custom::AdminSla, mariadb: true, type: :model do
  include_context 'with core workflow base'

  let(:payload) do
    base_payload.merge(
      'screen'     => 'edit',
      'class_name' => 'Sla',
    )
  end

  it 'does set first_response_time_in_text optional' do
    expect(result[:mandatory]['first_response_time_in_text']).to be(false)
  end

  it 'does set update_time_in_text optional' do
    expect(result[:mandatory]['update_time_in_text']).to be(false)
  end

  it 'does set solution_time_in_text optional' do
    expect(result[:mandatory]['solution_time_in_text']).to be(false)
  end

  describe 'on first_response_time_enabled' do
    let(:payload) do
      base_payload.merge(
        'screen'     => 'edit',
        'class_name' => 'Sla',
        'params'     => { 'first_response_time_enabled' => 'true' }
      )
    end

    it 'does set first_response_time_in_text mandatory' do
      expect(result[:mandatory]['first_response_time_in_text']).to be(true)
    end

    it 'does set update_time_in_text optional' do
      expect(result[:mandatory]['update_time_in_text']).to be(false)
    end

    it 'does set solution_time_in_text optional' do
      expect(result[:mandatory]['solution_time_in_text']).to be(false)
    end
  end

  describe 'on update_time_enabled' do
    let(:payload) do
      base_payload.merge(
        'screen'     => 'edit',
        'class_name' => 'Sla',
        'params'     => { 'update_time_enabled' => 'true', 'update_type' => 'update' }
      )
    end

    it 'does set first_response_time_in_text optional' do
      expect(result[:mandatory]['first_response_time_in_text']).to be(false)
    end

    it 'does set update_time_in_text mandatory' do
      expect(result[:mandatory]['update_time_in_text']).to be(true)
    end

    it 'does set solution_time_in_text optional' do
      expect(result[:mandatory]['solution_time_in_text']).to be(false)
    end
  end

  describe 'on solution_time_enabled' do
    let(:payload) do
      base_payload.merge(
        'screen'     => 'edit',
        'class_name' => 'Sla',
        'params'     => { 'solution_time_enabled' => 'true' }
      )
    end

    it 'does set first_response_time_in_text optional' do
      expect(result[:mandatory]['first_response_time_in_text']).to be(false)
    end

    it 'does set update_time_in_text optional' do
      expect(result[:mandatory]['update_time_in_text']).to be(false)
    end

    it 'does set solution_time_in_text mandatory' do
      expect(result[:mandatory]['solution_time_in_text']).to be(true)
    end
  end
end
