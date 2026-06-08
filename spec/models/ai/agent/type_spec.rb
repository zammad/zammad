# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Agent::Type, :aggregate_failures, current_user_id: 1, type: :model do
  describe '.available_types' do
    it 'returns all available AI agent types' do
      expect(described_class.available_types).to be_an(Array)

      expect(described_class.available_types.map(&:name)).to include(
        'AI::Agent::Type::TicketGroupDispatcher',
        'AI::Agent::Type::TicketCategorizer',
        'AI::Agent::Type::TicketTagger',
      )
    end
  end

  describe '.available_type_data' do
    it 'returns data for all available AI agent types' do
      type_data = described_class.available_type_data

      expect(type_data).to be_an(Array)
        .and include(**AI::Agent::Type::TicketGroupDispatcher.new.data)
    end
  end

  describe '#precondition_checks' do
    let(:ticket) { create(:ticket) }
    let(:type)   { described_class.new(type_enrichment_data: {}) }

    it 'returns an empty array by default' do
      expect(type.precondition_checks(ticket:)).to eq([])
    end
  end

  describe 'enrichment_data merge' do
    let(:type_class) do
      Class.new(described_class) do
        def base_type_enrichment_data
          super.merge('flag_on' => true)
        end
      end
    end

    context 'when the same key is provided by the user and the base' do
      it 'the user value wins the merge (base acts as an overridable default)' do
        instance = type_class.new(type_enrichment_data: { 'flag_on' => false })

        expect(instance.enrichment_data['flag_on']).to be(false)
      end
    end

    context 'when the user provides no value for a base key' do
      it 'the base value is surfaced via enrichment_data' do
        instance = type_class.new

        expect(instance.enrichment_data['flag_on']).to be(true)
      end
    end
  end

  describe 'instruction template sanitization integration' do
    # The full sanitizer behavior lives in spec/lib/erb_sanitizer_spec.rb. These
    #   tests exist only to confirm AI::Agent::Type wires the sanitizer into the
    #   transform_structure pipeline so templates authored in concrete types are
    #   actually sanitized before the renderer runs.
    let(:type_class) do
      Class.new(described_class) do
        def base_type_enrichment_data
          super.merge('flag_on' => true, 'flag_off' => false)
        end
      end
    end

    def render_pipeline(template, instance)
      instance.send(:sanitize_instruction_template, template)
        .then { |sanitized| instance.send(:render_structure, sanitized) }
    end

    it 'keeps an allowed conditional body when the base value is truthy' do
      instance = type_class.new

      expect(render_pipeline('A<% if @objects[:type_enrichment_data].flag_on %>B<% end %>C', instance)).to eq('ABC')
    end

    it 'drops an allowed conditional body when the base value is falsy' do
      instance = type_class.new

      expect(render_pipeline('A<% if @objects[:type_enrichment_data].flag_off %>B<% end %>C', instance)).to eq('AC')
    end

    it 'escapes templates that reference unknown names' do
      instance = type_class.new
      payload  = '<% if @objects[:type_enrichment_data].unknown %>X<% end %>'

      expect(render_pipeline(payload, instance)).to eq(payload)
    end

    context 'with injection attempts via user-provided enrichment data' do
      it 'does not activate conditionals smuggled in enrichment values' do
        # The note value is interpolated via `#{type_enrichment_data.note}`. The
        #   value gets `<%` escaped to `<%%` by sanitize_template_value before
        #   reaching ERB, so the injected tags emerge as literal text, not an
        #   active conditional.
        instance = type_class.new(type_enrichment_data: { 'note' => '<% if @objects[:type_enrichment_data].flag_on %>X<% end %>' })
        result   = render_pipeline('before #{type_enrichment_data.note} after', instance) # rubocop:disable Lint/InterpolationCheck

        expect(result).not_to eq('before X after')
        expect(result).to include('flag_on')
      end
    end

    context 'with placeholder replacement' do
      let(:placeholder_type_class) do
        Class.new(type_class) do
          def placeholder_field_names
            ['note']
          end
        end
      end

      it 'sanitizes ERB tags smuggled in placeholder values before rendering' do
        instance = placeholder_type_class.new(type_enrichment_data: { 'note' => '<%= 1 + 1 %>' })
        result   = instance.send(:transform_structure, { 'note' => '#{placeholder.note}' }) # rubocop:disable Lint/InterpolationCheck

        expect(result['note']).to eq('<%= 1 + 1 %>')
      end
    end
  end
end
