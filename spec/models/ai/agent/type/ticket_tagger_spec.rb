# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Agent::Type::TicketTagger, :aggregate_failures, current_user_id: 1, type: :model do
  describe '.execution_definition' do
    let(:type_enrichment_data) { { 'tagging_principles' => 'Prefer short tags.' } }
    let(:agent_type)           { described_class.new(type_enrichment_data:) }

    it 'renders the result structure and tagging principles' do
      result = agent_type.execution_definition

      expect(result).to be_a(Hash)
      expect(result['result_structure']['tags']).to eq(['string'])
      expect(result['instruction']).to include('Prefer short tags.')
    end
  end

  describe 'tag_new conditional in instruction' do
    let(:agent_type) { described_class.new(type_enrichment_data: {}) }

    context 'when tag_new is enabled' do
      before { Setting.set('tag_new', true) }

      it 'includes the New Tags Rules section' do
        expect(agent_type.execution_definition['instruction']).to include('New Tags Rules:')
      end
    end

    context 'when tag_new is disabled' do
      before { Setting.set('tag_new', false) }

      it 'omits the New Tags Rules section but keeps the base sections' do
        instruction = agent_type.execution_definition['instruction']

        expect(instruction).not_to include('New Tags Rules:')
        expect(instruction)
          .to include('Apply the following principles when assigning tags:')
          .and include('Language:')
          .and include('Priority Rules:')
          .and include('Tag Count & Mode:')
      end
    end
  end

  describe '.execution_action_definition' do
    context 'when tag_operator is add' do
      let(:agent_type) { described_class.new(type_enrichment_data: { 'tag_operator' => 'add' }) }

      it 'uses add operator' do
        result = agent_type.execution_action_definition

        expect(result['mapping']['ticket.tags']).to include(
          'operator' => 'add',
          'value'    => '#{ai_agent_result.tags}', # rubocop:disable Lint/InterpolationCheck
        )
      end
    end

    context 'when tag_operator is fill' do
      let(:agent_type) { described_class.new(type_enrichment_data: { 'tag_operator' => 'fill' }) }

      it 'maps fill to add operator' do
        result = agent_type.execution_action_definition

        expect(result['mapping']['ticket.tags']).to include('operator' => 'add')
      end
    end

    context 'when tag_operator is replace' do
      let(:agent_type) { described_class.new(type_enrichment_data: { 'tag_operator' => 'replace' }) }

      it 'uses replace operator' do
        result = agent_type.execution_action_definition

        expect(result['mapping']['ticket.tags']).to include('operator' => 'replace')
      end
    end
  end

  describe 'number_of_tags rendering across tag_operator modes' do
    let(:ticket) { create(:ticket) }

    context 'when tag_operator is fill and the ticket already has tags' do
      let(:agent_type) { described_class.new(type_enrichment_data: { 'tag_operator' => 'fill', 'number_of_tags' => 5 }) }

      before { 2.times { |i| ticket.tag_add("tag-#{i}", 1) } }

      it 'overrides number_of_tags with the remaining slot count' do
        instruction = agent_type.execution_definition(context: { ticket: })['instruction']

        expect(instruction).to include('Keep the existing tags and add up to 3 new tags. Return no more than 3 tags.')
        expect(instruction).not_to include('Keep the existing tags and add up to 5 new tags.')
      end
    end

    context 'when tag_operator is fill and no ticket is passed in context' do
      let(:agent_type) { described_class.new(type_enrichment_data: { 'tag_operator' => 'fill', 'number_of_tags' => 5 }) }

      it 'keeps the configured number_of_tags' do
        instruction = agent_type.execution_definition['instruction']

        expect(instruction).to include('Keep the existing tags and add up to 5 new tags. Return no more than 5 tags.')
      end
    end

    context 'when tag_operator is add' do
      let(:agent_type) { described_class.new(type_enrichment_data: { 'tag_operator' => 'add', 'number_of_tags' => 5 }) }

      it 'uses the configured number_of_tags verbatim (runtime does not override)' do
        ticket.tag_add('existing', 1)
        instruction = agent_type.execution_definition(context: { ticket: })['instruction']

        expect(instruction).to include('Keep the existing tags and add up to 5 new tags. Return no more than 5 tags.')
        expect(instruction).not_to include('Generate up to 5 additional tags.')
      end
    end
  end

  describe '#precondition_checks' do
    let(:ticket)     { create(:ticket) }
    let(:agent_type) { described_class.new(type_enrichment_data: { 'number_of_tags' => 2, 'tag_operator' => 'fill' }) }

    context 'when ticket is below the limit' do
      before { ticket.tag_add('only-one', 1) }

      it 'returns checks all passing' do
        expect(agent_type.precondition_checks(ticket:)).to all(be_passed)
      end
    end

    context 'when ticket has reached number_of_tags with fill operator' do
      before { 2.times { |i| ticket.tag_add("tag-#{i}", 1) } }

      it 'returns a failing check' do
        expect(agent_type.precondition_checks(ticket:).first.passed?).to be(false)
      end
    end

    context 'when tag_operator is add' do
      let(:agent_type) { described_class.new(type_enrichment_data: { 'number_of_tags' => 1, 'tag_operator' => 'add' }) }

      before { ticket.tag_add('existing', 1) }

      it 'returns checks all passing' do
        expect(agent_type.precondition_checks(ticket:)).to all(be_passed)
      end
    end

    context 'when tag_operator is replace' do
      let(:agent_type) { described_class.new(type_enrichment_data: { 'number_of_tags' => 1, 'tag_operator' => 'replace' }) }

      before { ticket.tag_add('existing', 1) }

      it 'returns checks all passing' do
        expect(agent_type.precondition_checks(ticket:)).to all(be_passed)
      end
    end

    context 'when tag_new is disabled and no Tag::Item exists' do
      let(:agent_type) { described_class.new(type_enrichment_data: { 'number_of_tags' => 1, 'tag_operator' => 'add' }) }

      before do
        Setting.set('tag_new', false)
        Tag::Item.destroy_all
      end

      it 'fails the tag_pool_available check' do
        check = agent_type.precondition_checks(ticket:).find { |c| c.name == :tag_pool_available }

        expect(check.passed?).to be(false)
      end
    end

    context 'when tag_new is disabled but tags exist in the system' do
      let(:agent_type) { described_class.new(type_enrichment_data: { 'number_of_tags' => 1, 'tag_operator' => 'add' }) }

      before do
        Setting.set('tag_new', false)
        Tag::Item.lookup_by_name_and_create('existing-tag')
      end

      it 'passes the tag_pool_available check' do
        expect(agent_type.precondition_checks(ticket:)).to all(be_passed)
      end
    end

    context 'when tag_new is enabled and no Tag::Item exists' do
      let(:agent_type) { described_class.new(type_enrichment_data: { 'number_of_tags' => 1, 'tag_operator' => 'add' }) }

      before do
        Setting.set('tag_new', true)
        Tag::Item.destroy_all
      end

      it 'passes the tag_pool_available check without hitting the database' do
        allow(Tag::Item).to receive(:exists?)

        expect(agent_type.precondition_checks(ticket:)).to all(be_passed)
        expect(Tag::Item).not_to have_received(:exists?)
      end
    end
  end
end
