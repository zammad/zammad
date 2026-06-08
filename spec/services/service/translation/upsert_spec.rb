# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Translation::Upsert, current_user_id: 1 do
  subject(:service_result) { described_class.execute(locale:, source:, target:) }

  describe '#execute' do
    let(:locale) { 'de-de' }

    context 'when translation record already exists' do
      let(:source) { 'New' }
      let(:target) { 'Neu2' }

      it 'use existing record' do
        translation_for_new = Translation.find_source('de-de', 'New')

        expect { service_result }.to change { translation_for_new.reload.target }.to(target)
      end
    end

    context 'when translation record does not exist' do
      let(:source) { SecureRandom.uuid }
      let(:target) { 'Other' }

      it 'create new record' do
        expect { service_result }
          .to change(Translation, :count).by(1)
          .and change { Translation.find_by(locale:, source:)&.attributes&.symbolize_keys&.slice(:target, :target_initial, :is_synchronized_from_codebase) }
          .from(nil).to({ target:, target_initial: target, is_synchronized_from_codebase: false })
      end
    end
  end
end
