# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/mixin/has_backends_examples'

RSpec.describe ObjectManager::Attribute::Validation, application_handle: 'application_server' do
  it_behaves_like 'Mixin::HasBackends'

  it 'is a ActiveModel::Validator' do
    expect(described_class).to be < ActiveModel::Validator
  end

  describe '#validate' do

    subject { described_class.new }

    let(:record)  { build(:user) }
    let(:backend) { spy }

    around do |example|
      original_backends = described_class.backends.dup
      begin
        example.run
      ensure
        described_class.backends = original_backends
      end
    end

    before do
      described_class.backends = Set[backend]
    end

    it 'sends .validate to backends' do
      subject.validate(record)
      expect(backend).to have_received(:validate).with(record: record, attribute: instance_of(ObjectManager::Attribute)).at_least(:once)
    end

    context 'for cached ObjectManager::Attribute records' do

      it 'fetches current records when in memory Cache is blank' do
        allow(ObjectManager::Attribute).to receive(:where).and_call_original
        subject.validate(record)
        expect(ObjectManager::Attribute).to have_received(:where).twice
      end

      it "doesn't fetch current records when in memory Cache is valid" do
        subject.validate(record)

        allow(ObjectManager::Attribute).to receive(:where).and_call_original
        subject.validate(record)
        expect(ObjectManager::Attribute).to have_received(:where).once
      end

      it 'fetches current records when in memory Cache is outdated' do
        subject.validate(record)

        ObjectManager::Attribute.last.touch

        allow(ObjectManager::Attribute).to receive(:where).and_call_original
        subject.validate(record)
        expect(ObjectManager::Attribute).to have_received(:where).twice
      end
    end

    context 'when no validation is performed' do

      it 'is skipped because of irrelevant ApplicationHandleInfo', application_handle: 'non_application_server' do
        subject.validate(record)
        expect(backend).not_to have_received(:validate)
      end

      it 'is skipped because of import_mode is active' do
        allow(Setting).to receive(:get).with('import_mode').and_return(true)
        subject.validate(record)
        expect(backend).not_to have_received(:validate)
      end

      it 'is skipped because of unchanged attributes' do
        record.save!
        RSpec::Mocks.space.proxy_for(backend).reset
        subject.validate(record)
        expect(backend).not_to have_received(:validate)
      end

      context 'when caused by ObjectManager::Attribute records' do

        it 'is skipped because no custom attributes are present' do
          ObjectManager::Attribute.update(editable: false)
          subject.validate(record)
          expect(backend).not_to have_received(:validate)
        end

        it 'is skipped because no active attributes are present' do
          ObjectManager::Attribute.update(active: false)
          subject.validate(record)
          expect(backend).not_to have_received(:validate)
        end
      end
    end

    context 'when custom attribute exists' do
      before do
        allow(subject).to receive(:attributes_unchanged?)
      end

      it 'runs validation in default context' do
        ApplicationHandleInfo.in_context(nil) do
          subject.validate(record)
        end

        expect(subject).to have_received(:attributes_unchanged?)
      end

      it 'does not run validations in contexts that do not use custom attributes' do
        ApplicationHandleInfo.in_context('merge') do
          subject.validate(record)
        end

        expect(subject).not_to have_received(:attributes_unchanged?)
      end
    end
  end

  describe '#validation_needed' do
    it 'runs validation in default context' do
      ApplicationHandleInfo.in_context(nil) do
        expect(subject.send(:validation_needed?)).to be true
      end
    end

    it 'does not run validations in contexts that do not use custom attributes' do
      ApplicationHandleInfo.in_context('merge') do
        expect(subject.send(:validation_needed?)).to be false
      end
    end
  end
end
