# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ObjectManagerAttributeDateRemoveFuturePast, type: :db_migration do
  context 'when Date ObjectManager::Attribute exists' do
    let(:attribute)   { create(:object_manager_attribute_date) }
    let(:data_option) { attribute.data_option.merge(future: false, past: false) }

    before do
      # The factory does not contain the obsolete options anymore.
      attribute.update_columns(data_option: data_option)
    end

    it 'removes future and past data_option' do
      expect { migrate }.to change { attribute.reload.data_option.keys }
        .from(include('future', 'past'))
        .to(not_include('future', 'past'))
    end

    context 'when incomplete data_option is given' do
      let(:data_option) { attribute.data_option.merge(future: false, past: false).except(:diff) }

      it 'adds missing :diff option' do
        expect { migrate }.to change { attribute.reload.data_option[:diff] }.from(nil).to(24)
      end
    end
  end
end
