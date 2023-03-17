# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Zammad::TranslationCatalog::Extractor::Chat do
  subject(:extractor_module) { described_class.new(options: {}) }

  let(:filename) { 'myfile' }
  let(:result_strings) do
    extractor_module.extract_from_string(string, filename)
    extractor_module.extracted_strings.keys.sort
  end

  context 'with strings to be found' do
    let(:string) do
      <<~CODE
        var value = {
          title: 'My title',
          scrollHint: "My scroll hint",
          otherKey: "Not found",
        }
      CODE
    end

    it 'finds the correct strings' do
      expect(result_strings).to eq(['My scroll hint', 'My title'])
    end
  end
end
