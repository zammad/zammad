# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MonitoringHelper::Status do
  let(:instance) { described_class.new }

  describe '#fetch_status' do
    before do
      allow(instance).to receive(:counts).and_return(:count)
      allow(instance).to receive(:last_created_at).and_return(:created)
      allow(instance).to receive(:last_login).and_return(:login)
      allow(instance).to receive(:agents_count).and_return(:agents)
      allow(instance).to receive(:storage).and_return(:storage_size)
    end

    it 'returns output of computation methods' do
      expect(instance.fetch_status).to include(
        counts: :count, last_created_at: :created, last_login: :login, agents: :agents, storage: :storage_size
      )
    end
  end

  describe '#last_login' do
    it 'returns nil if no last login' do
      expect(instance.send(:last_login)).to be_nil
    end

    it 'returns latest last_login' do
      freeze_time
      create(:agent, last_login: 2.days.ago)
      create(:agent, last_login: 1.day.ago)
      expect(instance.send(:last_login)).to eq 1.day.ago
    end
  end

  describe '#agents_count' do
    it 'returns count of agents' do
      create_list(:agent, 5)
      create_list(:customer, 5)

      expect(instance.send(:agents_count)).to be 5
    end
  end

  describe '#counts' do
    include_context 'basic Knowledge Base'

    before do
      stub_const("#{described_class}::INCLUDE_CLASSES", [KnowledgeBase::Category, KnowledgeBase::Answer])
    end

    it 'counts items' do
      published_answer && draft_answer

      expect(instance.send(:counts)).to eq({ 'knowledge_base_categories' => 1, 'knowledge_base_answers' => 2 })
    end
  end

  describe '#last_created_at' do
    include_context 'basic Knowledge Base'

    before do
      stub_const("#{described_class}::INCLUDE_CLASSES", [KnowledgeBase::Category, KnowledgeBase::Answer])

      freeze_time
      category

      travel 12.hours
      published_answer

      travel 12.hours
      draft_answer
    end

    it 'counts items' do
      expect(instance.send(:last_created_at)).to eq({ 'knowledge_base_categories' => 1.day.ago, 'knowledge_base_answers' => Time.current })
    end
  end

  describe '#storage' do
    case ActiveRecord::Base.connection_db_config.configuration_hash[:adapter]
    when 'postgresql'
      it 'returns size of attached files' do
        20.times { create(:store).update! size: 65_000_000 }

        expect(instance.send(:storage)).to include({ kB: 1_269_531, MB: 1239, GB: 1 })
      end

      it 'returns nil if no files attached' do # rubocop:disable RSpec/RepeatedExample
        expect(instance.send(:storage)).to be_nil
      end
    when 'mysql'
      it 'returns nil' do # rubocop:disable RSpec/RepeatedExample
        expect(instance.send(:storage)).to be_nil
      end
    end
  end
end
