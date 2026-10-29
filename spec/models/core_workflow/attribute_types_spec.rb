# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/core_workflow/base'

RSpec.describe 'CoreWorkflow > Attribute types', db_strategy: :reset, type: :model do
  include_context 'with core workflow base'
  include CoreWorkflowFieldMatrix

  let(:object_name) { 'Ticket' }

  before do
    create_matrix_fields
    create_matrix_workflows
  end

  def results_of(action)
    field = matrix_field(action)

    {
      visibility:      result[:visibility][field],
      mandatory:       result[:mandatory][field],
      readonly:        result[:readonly][field],
      restrict_values: result[:restrict_values][field],
      select:          result[:select][field],
      fill_in:         result[:fill_in][field],
    }.compact
  end

  shared_examples 'performing the field state actions' do
    it 'performs the visibility and mandatory actions', :aggregate_failures do
      expect(results_of(:show)).to include(visibility: 'show')
      expect(results_of(:hide)).to include(visibility: 'hide')
      expect(results_of(:remove)).to include(visibility: 'remove')
      expect(results_of(:set_optional)).to include(mandatory: false)
      expect(results_of(:set_mandatory)).to include(mandatory: true)
    end
  end

  shared_examples 'performing the readonly actions' do
    it 'performs the readonly actions', :aggregate_failures do
      expect(results_of(:unset_readonly)).to include(readonly: false)
      expect(results_of(:set_readonly)).to include(readonly: true)
    end
  end

  shared_examples 'performing the fill in actions' do
    it 'performs the fill in actions', :aggregate_failures do
      expect(results_of(:fill_in)).to include(fill_in: '4cddb2twza')
      expect(results_of(:fill_in_empty_with_match)).to include(fill_in: '9999')
      expect(results_of(:fill_in_empty_without_match)).to include(fill_in: '4cddb2twza')
    end
  end

  shared_examples 'performing the option actions' do |restricted:, selected:, auto_selected:|
    it 'performs the option actions', :aggregate_failures do
      expect(results_of(:restrict_values)[:restrict_values]).to eq(restricted)
      expect(results_of(:select)).to include(select: selected)
      expect(results_of(:auto_select)).to include(select: auto_selected)
    end
  end

  context 'with an input attribute' do
    let(:matrix_type) { :input }

    it_behaves_like 'performing the field state actions'
    it_behaves_like 'performing the readonly actions'
    it_behaves_like 'performing the fill in actions'
  end

  context 'with a textarea attribute' do
    let(:matrix_type) { :textarea }

    it_behaves_like 'performing the field state actions'
    it_behaves_like 'performing the readonly actions'
    it_behaves_like 'performing the fill in actions'
  end

  context 'with a select attribute' do
    let(:matrix_type) { :select }

    it_behaves_like 'performing the field state actions'
    it_behaves_like 'performing the readonly actions'
    it_behaves_like 'performing the option actions', restricted: %w[key_1 key_3], selected: 'key_3', auto_selected: 'key_3'
  end

  context 'with a multiselect attribute' do
    let(:matrix_type) { :multiselect }

    it_behaves_like 'performing the field state actions'
    it_behaves_like 'performing the readonly actions'
    it_behaves_like 'performing the option actions', restricted: %w[key_1 key_3], selected: %w[key_3], auto_selected: %w[key_3]
  end

  context 'with a boolean attribute' do
    let(:matrix_type) { :boolean }

    it_behaves_like 'performing the field state actions'

    # The params of a boolean field already hold a value, so select and auto_select
    #   report nothing here; the browser examples cover both.
    it 'restricts the values' do
      expect(results_of(:restrict_values)[:restrict_values]).to eq(%w[false])
    end
  end

  context 'with a tree select attribute' do
    let(:matrix_type) { :tree_select }

    it_behaves_like 'performing the field state actions'
    it_behaves_like 'performing the readonly actions'
    it_behaves_like 'performing the option actions',
                    restricted:    ['Incident', 'Incident::Hardware', 'Incident::Hardware::Monitor'],
                    selected:      'Incident::Hardware::Monitor',
                    auto_selected: 'Incident'
  end

  context 'with a multi tree select attribute' do
    let(:matrix_type) { :multi_tree_select }

    it_behaves_like 'performing the field state actions'
    it_behaves_like 'performing the readonly actions'
    it_behaves_like 'performing the option actions',
                    restricted:    ['Incident', 'Incident::Hardware', 'Incident::Hardware::Monitor'],
                    selected:      ['Incident::Hardware::Monitor'],
                    auto_selected: ['Incident']
  end

  context 'with a date attribute' do
    let(:matrix_type) { :date }

    it_behaves_like 'performing the field state actions'
    it_behaves_like 'performing the readonly actions'
  end

  context 'with a datetime attribute' do
    let(:matrix_type) { :datetime }

    it_behaves_like 'performing the field state actions'
    it_behaves_like 'performing the readonly actions'
  end
end
