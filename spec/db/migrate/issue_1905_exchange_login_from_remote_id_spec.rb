# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue1905ExchangeLoginFromRemoteId, type: :db_migration do

  let(:backend) { ::Import::Exchange }

  it 'removes :item_id from attributes' do

    invalid_config = {
      attributes: {
        item_id: 'login',
        some:    'other',
      }
    }

    valid_config = ActiveSupport::HashWithIndifferentAccess.new(
      attributes: {
        some: 'other',
      }
    )

    expect(backend).to receive(:config).and_return(invalid_config) # rubocop:disable RSpec/StubbedMock
    allow(backend).to receive(:config).and_call_original

    migrate

    expect(backend.config).to eq(valid_config)
  end

  context 'no changes' do

    it 'performs no action for new systems', system_init_done: false do
      expect(backend).not_to receive(:config)
      migrate
    end

    shared_examples 'irrelevant config' do
      it 'does not change the config' do
        allow(backend).to receive(:config).and_return(config)
        expect(backend).not_to receive(:config=)
        migrate
      end
    end

    context 'blank config' do
      let(:config) { nil }

      it_behaves_like 'irrelevant config'
    end

    context 'blank attributes' do
      let(:config) do
        {
          some: 'config'
        }
      end

      it_behaves_like 'irrelevant config'
    end

    context 'blank attribute :item_id' do
      let(:config) do
        {
          attributes: {
            some: 'mapping'
          }
        }
      end

      it_behaves_like 'irrelevant config'
    end

    context 'attribute :item_id not mapping to login' do

      let(:config) do
        {
          attributes: {
            item_id: 'other_local_attribute'
          }
        }
      end

      it_behaves_like 'irrelevant config'
    end
  end
end
