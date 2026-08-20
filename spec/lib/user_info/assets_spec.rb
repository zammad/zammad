# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UserInfo::Assets do
  describe '#check_level?' do
    context 'without a user' do
      subject(:assets) { described_class.new(nil) }

      # A cleared or never established context must not unlock agent or admin level data, that
      # is what made a lost request context leak unredacted assets to customers.
      it 'is not privileged', :aggregate_failures do
        expect(assets).not_to be_agent
        expect(assets).not_to be_admin
        expect(assets).not_to be_customer
      end

      it 'is privileged in a system context', :aggregate_failures do
        UserInfo.with_system_context do
          expect(assets).to be_agent
          expect(assets).to be_admin
        end
      end
    end

    context 'with a customer' do
      subject(:assets) { described_class.new(create(:customer).id) }

      it 'is customer level only', :aggregate_failures do
        expect(assets).to be_customer
        expect(assets).not_to be_agent
        expect(assets).not_to be_admin
      end

      it 'is not elevated by a system context' do
        UserInfo.with_system_context do
          expect(assets).not_to be_agent
        end
      end
    end

    context 'with an agent' do
      subject(:assets) { described_class.new(create(:agent).id) }

      it 'is agent level', :aggregate_failures do
        expect(assets).to be_agent
        expect(assets).not_to be_admin
      end
    end

    context 'with an admin' do
      subject(:assets) { described_class.new(create(:admin).id) }

      it 'is admin level' do
        expect(assets).to be_admin
      end
    end
  end
end
