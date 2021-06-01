# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'TriggerWebhookJob::RecordPayload backend' do |factory|

  describe 'const USER_ATTRIBUTE_BLACKLIST' do

    subject(:blacklist) { described_class.const_get(:USER_ATTRIBUTE_BLACKLIST) }

    it 'contains sensitive attributes' do
      expect(blacklist).to include('password')
    end
  end

  describe '#generate' do
    subject(:generate) { described_class.new(record).generate }
    let(:resolved_associations) { described_class.const_get(:ASSOCIATIONS).map(&:to_s) }
    let(:record) { build(factory) }

    it 'includes attributes with association names' do
      expect(generate).to include(record.attributes_with_association_names.except(*resolved_associations))
    end

    it 'resolves defined associations' do
      resolved_associations.each do |association|
        expect(generate[association]).to be_a(Hash)
      end
    end

    it 'does not contain blacklisted User attributes' do
      expect(generate['created_by']).not_to have_key('password')
    end
  end
end
