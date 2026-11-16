# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SearchIndexBackend::QueryString do
  describe '#to_bool' do
    def bool(query)
      described_class.new(query).to_bool { |part| part }
    end

    context 'with a query without fields and prohibited terms' do
      [
        'printer',
        'printer toner*',
        'printer OR toner',
        'printer AND toner || paper',
        'printer - toner',
        'printer and not toner',
        'printer (toner OR paper)^2 "out of order"~2 /pap[ei]r/',
      ].each do |query|
        it "returns '#{query}' as one part" do
          expect(bool(query)).to eq(query)
        end
      end
    end

    context 'with prohibited terms' do
      it 'returns a prohibited term' do
        expect(bool('!state.name: closed')).to eq({ bool: { must_not: ['state.name: closed'] } })
      end

      it 'returns prohibited terms' do
        expect(bool('-printer -toner')).to eq({ bool: { must_not: %w[printer toner] } })
      end

      it 'keeps the required terms together' do
        expect(bool('printer toner -paper')).to eq({ bool: { must: ['printer AND toner'], must_not: ['paper'] } })
      end

      ['NOT ', '!', '-'].each do |operator|
        it "supports the operator '#{operator.strip}'" do
          expect(bool("printer #{operator}toner")).to eq({ bool: { must: ['printer'], must_not: ['toner'] } })
        end
      end

      it 'supports phrases, boosts and fuzziness' do
        expect(bool('"out of order" -"paper jam"~2 printer^3')).to eq({ bool: { must: ['"out of order" AND printer^3'], must_not: ['"paper jam"~2'] } })
      end
    end

    context 'with fields' do
      it 'returns a term with a field as one part' do
        expect(bool('state.name:closed')).to eq('state.name:closed')
      end

      it 'separates terms with a field from the other terms' do
        expect(bool('printer state.name:new toner')).to eq({ bool: { must: ['printer AND toner', 'state.name:new'] } })
      end

      it 'keeps the spelling of a term with a field' do
        expect(bool('Re : printer toner')).to eq({ bool: { must: ['toner', 'Re : printer'] } })
      end

      it 'supports phrases, ranges and regular expressions' do
        expect(bool('title:"out of order" created_at:[2026-01-01 TO 2026-12-31] -article.body:/pap[ei]r/'))
          .to eq({ bool: { must: ['title:"out of order"', 'created_at:[2026-01-01 TO 2026-12-31]'], must_not: ['article.body:/pap[ei]r/'] } })
      end
    end

    context 'with groups' do
      it 'keeps a group without fields and prohibited terms together' do
        expect(bool('(printer OR toner) -paper')).to eq({ bool: { must: ['(printer OR toner)'], must_not: ['paper'] } })
      end

      it 'returns a group with a prohibited term' do
        expect(bool('printer (toner -paper)')).to eq({ bool: { must: ['printer', { bool: { must: ['toner'], must_not: ['paper'] } }] } })
      end

      it 'returns every term of a prohibited group' do
        expect(bool('-(printer toner)')).to eq({ bool: { must_not: [{ bool: { must: %w[printer toner] } }] } })
      end

      it 'applies the field of a group to its terms' do
        expect(bool('state.name:(new OR open) printer')).to eq({ bool: { must: ['printer', { bool: { should: %w[state.name:new state.name:open] } }] } })
      end

      it 'applies the field of a group to its prohibited term' do
        expect(bool('state.name:(NOT closed)')).to eq({ bool: { must_not: ['state.name:closed'] } })
      end
    end

    context 'with operators' do
      it 'returns optional terms' do
        expect(bool('printer OR toner -paper')).to eq({ bool: { should: %w[printer toner], must_not: ['paper'] } })
      end

      it 'keeps a prohibited term after an optional one prohibited' do
        expect(bool('printer OR NOT toner')).to eq({ bool: { should: ['printer'], must_not: ['toner'] } })
      end

      it 'makes the term before an operator required or optional' do
        expect(bool('printer AND toner OR paper -ink')).to eq({ bool: { must: ['printer'], should: %w[toner paper], must_not: ['ink'] } })
      end

      it 'supports the short operators' do
        expect(bool('+printer && toner || paper !ink')).to eq({ bool: { must: ['printer'], should: %w[toner paper], must_not: ['ink'] } })
      end
    end

    context 'with a query which can not be parsed' do
      [
        '(printer -toner',
        'printer -toner)',
        '"printer -toner',
        'printer -toner AND',
        'OR printer -toner',
        "#{'(' * 101}printer -toner#{')' * 101}",
      ].each do |query|
        it "returns '#{query.truncate(30)}' as one part" do
          expect(bool(query)).to eq(query)
        end
      end
    end
  end
end
