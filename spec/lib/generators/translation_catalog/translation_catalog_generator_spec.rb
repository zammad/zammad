# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Generators::TranslationCatalog::TranslationCatalogGenerator do
  context 'when escaping po strings' do
    it 'does the right thing' do
      # Use send() to call a method which must be private due to Thor's interface.
      expect(described_class.new.send(:escape_for_po, "My complex \n \" string \\ with quotes")).to eq('My complex \\n \\" string \\\\ with quotes')
    end
  end
end
