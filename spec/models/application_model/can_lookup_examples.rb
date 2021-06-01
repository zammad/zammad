# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'ApplicationModel::CanLookup' do
  describe '.lookup_keys' do
    it 'returns a subset of: id, name, login, email, number' do
      expect(described_class.lookup_keys)
        .to all(be_in(%i[id name login email number]))
    end

    it 'only includes attributes present on the model' do
      expect(described_class.lookup_keys)
        .to all(be_in(described_class.attribute_names.map(&:to_sym)))
    end
  end

  describe '.lookup' do
    around do |example|
      Rails.cache.clear
      example.run
      Rails.cache.clear
    end

    let!(:instance)          { create(described_class.name.underscore) }
    let(:valid_lookup_key)   { (described_class.lookup_keys - [:id]).sample }
    let(:invalid_lookup_key) { (described_class.attribute_names.map(&:to_sym) - described_class.lookup_keys).sample }

    it 'accepts exactly one attribute-value pair' do
      expect { described_class.lookup(id: instance.id, valid_lookup_key => 'foo') }
        .to raise_error(ArgumentError)
    end

    it 'only accepts attributes from .lookup_keys' do
      expect { described_class.lookup(invalid_lookup_key => 'foo') }
        .to raise_error(ArgumentError)
    end

    shared_examples 'per-attribute examples' do |attribute|
      it "finds records by #{attribute} (like .find_by)" do
        expect(described_class.lookup(attribute => instance.send(attribute))).to eq(instance)
      end

      describe "cache storage by #{attribute}" do
        context 'inside a DB transaction' do # provided by default RSpec config
          it 'leaves the cache untouched' do
            expect { described_class.lookup(attribute => instance.send(attribute)) }
              .not_to change { described_class.cache_get(instance.send(attribute)) }
          end
        end

        context 'outside a DB transaction' do
          before do
            allow(ActiveRecord::Base.connection)
              .to receive(:transaction_open?).and_return(false)
          end

          context 'when called for the first time' do
            it 'saves the value to the cache' do
              expect(Rails.cache)
                .to receive(:write)
                .with("#{described_class}::#{instance.send(attribute)}", instance, { expires_in: 4.hours })
                .and_call_original

              expect { described_class.lookup(attribute => instance.send(attribute)) }
                .to change { described_class.cache_get(instance.send(attribute)) }
                .to(instance)
            end
          end

          if described_class.type_for_attribute(attribute).type == :string
            # https://github.com/zammad/zammad/issues/3121
            it 'retrieves results from cache with value as symbol' do
              expect(described_class.lookup(attribute => instance.send(attribute).to_sym)).to be_present
            end
          end

          context 'when called a second time' do
            before { described_class.lookup(attribute => instance.send(attribute)) }

            it 'retrieves results from cache' do
              expect(Rails.cache)
                .to receive(:read)
                .with("#{described_class}::#{instance.send(attribute)}")

              described_class.lookup(attribute => instance.send(attribute))
            end

            if attribute != :id
              context 'after it has been updated' do
                let!(:old_attribute_val) { instance.send(attribute) }
                let!(:new_attribute_val) { instance.send(attribute).next }

                it 'moves the record to a new cache key' do
                  expect { instance.update(attribute => new_attribute_val) }
                    .to change { described_class.cache_get(old_attribute_val) }.to(nil)

                  expect { described_class.lookup({ attribute => instance.send(attribute) }) }
                    .to change { described_class.cache_get(new_attribute_val) }.to(instance)
                end
              end
            end

            context 'after it has been destroyed' do
              it 'returns nil' do
                expect { instance.destroy }
                  .to change { described_class.cache_get(instance.send(attribute)) }
                  .to(nil)
              end
            end
          end
        end
      end
    end

    described_class.lookup_keys.each do |key|
      include_examples 'per-attribute examples', key
    end
  end
end
