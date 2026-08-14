# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe IdentifierName do
  describe '.encode' do
    it 'keeps an identifier without namespace' do
      expect(described_class.encode('Ticket')).to eq('Ticket')
    end

    it 'encodes the namespace separator of a class name' do
      expect(described_class.encode('ProjectBaller::Project')).to eq('ProjectBaller__Project')
    end

    # Enum values are built from identifiers which are no class names as well,
    #   e.g. the channel areas.
    it 'encodes the namespace separator of any identifier' do
      expect(described_class.encode('Email::Account')).to eq('Email__Account')
    end

    it 'encodes every namespace separator' do
      expect(described_class.encode('A::B::C')).to eq('A__B__C')
    end
  end
end
