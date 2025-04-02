# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CanSelector::AdvancedSorting do
  let(:object)   { Ticket }
  let(:locale)   { 'de-de' }
  let(:instance) { described_class.new(input, locale, object) }

  describe '#calculate_sorting' do
    context 'when sorting according to a string' do
      let(:input) { 'number ASC' }

      it 'returns a string' do
        expect(instance.calculate_sorting).to eq(input)
      end

    end

    context 'when sorting according to a hash' do
      let(:input) { { column: 'article_count', direction: 'ASC' } }

      if ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2'
        it 'returns the calculated MySQL option' do
          expect(instance.calculate_sorting).to eq('`tickets`.`article_count` ASC')
        end
      else
        it 'returns the calculated option' do
          expect(instance.calculate_sorting).to eq('"tickets"."article_count" ASC')
        end
      end

      it 'forwards given arguments to sorting backend' do
        allow(CanSelector::AdvancedSorting::DefaultSort).to receive(:new).and_call_original

        instance.calculate_sorting

        expect(CanSelector::AdvancedSorting::DefaultSort)
          .to have_received(:new)
          .with(input, locale, object)
          .once
      end
    end

    context 'when sorting according to an array' do
      let(:input) do
        [
          { column: 'article_count', direction: 'ASC' },
          'title DESC',
        ]
      end

      it 'returns parsed array members in the same order' do
        expect(instance.calculate_sorting)
          .to eq([
                   if ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2'
                     '`tickets`.`article_count` ASC'
                   else
                     '"tickets"."article_count" ASC'
                   end,
                   'title DESC',
                 ])
      end

      it 'forwards given arguments to sorting backend' do
        allow(CanSelector::AdvancedSorting::DefaultSort).to receive(:new).and_call_original

        instance.calculate_sorting

        expect(CanSelector::AdvancedSorting::DefaultSort)
          .to have_received(:new)
          .with(input[0], locale, object)
          .once
      end
    end
  end
end
