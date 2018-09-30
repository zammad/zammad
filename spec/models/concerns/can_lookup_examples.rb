require 'rails_helper'

RSpec.shared_examples 'CanLookup' do
  describe '::lookup' do
    let(:subject)            { described_class }
    let(:ensure_instance)    { create(subject.to_s.downcase) if subject.none? }
    let(:string_attributes)  { (%i[name login email number] & subject.attribute_names.map(&:to_sym)) }
    let(:non_attributes)     { (%i[id name login email number] - subject.attribute_names.map(&:to_sym)) }
    let(:lookup_id)          { 1 }
    let(:cache_key)          { "#{subject}::#{lookup_id}" }
    let(:cache_expiry_param) { { expires_in: 7.days } }

    it 'finds records by id (like ::find_by)' do
      ensure_instance

      expect(subject.lookup(id: lookup_id)).to eql(subject.find_by(id: lookup_id))
    end

    it 'finds records by other attributes (like ::find_by)' do
      ensure_instance

      # don't run this example on models with no valid string attributes
      if string_attributes.select! { |a| subject.pluck(a).any? }
        attribute_name = string_attributes.sample
        attribute_value = subject.pluck(target_attribute).sample

        expect(subject.lookup(attribute_name => attribute_value))
          .to eql(subject.find_by(attribute_name => attribute_value))
      end
    end

    it 'only accepts attributes that uniquely identify the record' do
      expect { subject.lookup(created_by_id: 1) }
        .to raise_error(ArgumentError)
    end

    it 'accepts exactly one attribute-value pair' do
      expect { subject.lookup(:id => lookup_id, string_attributes.sample => 'foo') }
        .to raise_error(ArgumentError)
    end

    it 'does not accept attributes not present in model' do
      expect { subject.lookup(non_attributes.sample => 'foo') }
        .to raise_error(ArgumentError)
    end

    it 'saves results to cache' do
      ensure_instance
      allow(Rails.cache)
        .to receive(:write)
        .and_call_original

      subject.lookup(id: lookup_id)

      expect(Rails.cache)
        .to have_received(:write)
        .with(cache_key, subject.first, cache_expiry_param)
    end

    it 'retrieves results from cache, if stored' do
      ensure_instance
      allow(Rails.cache)
        .to receive(:read)
        .and_call_original

      subject.lookup(id: lookup_id)

      expect(Rails.cache)
        .to have_received(:read)
        .with(cache_key)
    end
  end
end
