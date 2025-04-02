# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Translation::Upsert, current_user_id: 1 do
  describe '#execute' do
    let(:locale)                     { 'de-de' }
    let(:translation_upsert_service) { described_class.new(locale:, source:, target:) }

    context 'when translation record already exists' do
      let(:source)                      { 'New' }
      let(:target)                      { 'Neu2' }

      it 'use existing record' do
        translation_for_new = Translation.find_source('de-de', 'New')

        expect { translation_upsert_service.execute }.to change { translation_for_new.reload.target }.to(target)
      end
    end

    context 'when translation record does not exist', :aggregate_failures do
      let(:source)                      { SecureRandom.uuid }
      let(:target)                      { 'Other' }

      it 'create new record' do
        expect { translation_upsert_service.execute }.to change(Translation, :count).by(1)
        expect(Translation.last).to have_attributes(locale:, source:, target:, target_initial: target, is_synchronized_from_codebase: false)
      end
    end
  end
end
