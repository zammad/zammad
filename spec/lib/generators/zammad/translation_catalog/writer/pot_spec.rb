# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Zammad::TranslationCatalog::Writer::Pot do
  context 'when escaping po strings' do
    it 'does the right thing' do
      expect(described_class.new(options: {}).send(:escape_for_po, "My complex \n \" string \\ with quotes")).to eq('My complex \\n \\" string \\\\ with quotes')
    end
  end
end
