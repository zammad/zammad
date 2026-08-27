# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AuditLog::ObjectTypeLabels do
  describe '.label_for' do
    context 'with a mapped class name' do
      it 'returns the configured label' do
        expect(described_class.label_for('SSLCertificate')).to eq('SSL')
      end
    end

    context 'with an unmapped class name' do
      it 'titleizes simple class names' do
        expect(described_class.label_for('Role')).to eq('Role')
      end

      it 'titleizes camelCase class names' do
        expect(described_class.label_for('KnowledgeBase')).to eq('Knowledge Base')
      end

      it 'titleizes namespaced class names' do
        expect(described_class.label_for('ObjectManager::Attribute')).to eq('Object Manager Attribute')
      end

      it 'falls back to the titleized class name for an unknown class' do
        expect(described_class.label_for('Some::UnknownClass')).to eq('Some Unknown Class')
      end
    end

    context 'with a blank value' do
      it 'returns an empty string for nil' do
        expect(described_class.label_for(nil)).to eq('')
      end

      it 'returns an empty string for a blank value' do
        expect(described_class.label_for('')).to eq('')
      end
    end

    it 'resolves every audited model without an explicit label to an existing catalog entry' do
      audited_classes = ApplicationModel.descendants.select { |model| model.include?(HasAuditLogs) }
      unmapped_classes = audited_classes.reject { |klass| described_class::LABELS.key?(klass.name) }

      unresolved = unmapped_classes.reject do |klass|
        label = described_class.label_for(klass.name)
        Translation.exists?(source: label, locale: 'de-de')
      end

      expect(unresolved).to be_empty
    end
  end
end
