# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Models do

  describe '.merge' do

    context 'when ExternalSync references are present' do

      shared_examples 'migrates entries' do |model|

        let(:factory_name) { model.downcase.to_sym }
        let(:source) { create(factory_name) }
        let(:target) { create(factory_name) }

        it 'sends ExternalSync.migrate' do
          allow(ExternalSync).to receive(:migrate)
          described_class.merge(model, source.id, target.id)
          expect(ExternalSync).to have_received(:migrate).with(model, source.id, target.id)
        end
      end

      it_behaves_like 'migrates entries', 'User'
    end
  end
end
