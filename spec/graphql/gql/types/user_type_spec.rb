# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Types::UserType, type: :graphql do
  let(:instance) { described_class.send(:new, user, nil) }

  describe '#out_of_office' do
    subject(:out_of_office) { instance.out_of_office }

    context 'when OOO is disabled' do
      let(:user) { create(:agent, out_of_office: false) }

      it 'returns false' do
        expect(out_of_office).to be(false)
      end
    end

    context 'when OOO is enabled with a current date range' do
      let(:user) do
        create(:agent,
               out_of_office:                true,
               out_of_office_start_at:       Time.current.yesterday.to_date,
               out_of_office_end_at:         Time.current.tomorrow.to_date,
               out_of_office_replacement_id: create(:agent).id)
      end

      it 'returns true' do
        expect(out_of_office).to be(true)
      end
    end

    context 'when OOO is enabled but the date range has expired' do
      let(:user) do
        create(:agent,
               out_of_office:                true,
               out_of_office_start_at:       2.weeks.ago.to_date,
               out_of_office_end_at:         1.week.ago.to_date,
               out_of_office_replacement_id: create(:agent).id)
      end

      it 'returns false' do
        expect(out_of_office).to be(false)
      end
    end
  end

  describe '#out_of_office_replacement' do
    subject(:out_of_office_replacement) { instance.out_of_office_replacement }

    let(:replacement) { create(:agent) }

    context 'when OOO is disabled' do
      let(:user) do
        create(:agent,
               out_of_office:                false,
               out_of_office_replacement_id: replacement.id)
      end

      it 'returns nil' do
        expect(out_of_office_replacement).to be_nil
      end
    end

    context 'when OOO is enabled with a current date range' do
      let(:user) do
        create(:agent,
               out_of_office:                true,
               out_of_office_start_at:       Time.current.yesterday.to_date,
               out_of_office_end_at:         Time.current.tomorrow.to_date,
               out_of_office_replacement_id: replacement.id)
      end

      it 'returns the replacement agent' do
        expect(out_of_office_replacement).to eq(replacement)
      end
    end

    context 'when OOO is enabled but the date range has expired' do
      let(:user) do
        create(:agent,
               out_of_office:                true,
               out_of_office_start_at:       2.weeks.ago.to_date,
               out_of_office_end_at:         1.week.ago.to_date,
               out_of_office_replacement_id: replacement.id)
      end

      it 'returns nil' do
        expect(out_of_office_replacement).to be_nil
      end
    end
  end
end
