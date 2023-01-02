# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Zammad::TranslationCatalog::Extractor::RailsErrorMessages do
  subject(:extractor_module) { described_class.new(options: {}) }

  let(:result_strings) do
    extractor_module.extract_translatable_strings
  end

  it 'finds strings from activemodel' do
    expect(result_strings).to include("can't be empty")
  end

  it 'finds strings from activerecord' do
    expect(result_strings).to include('Cannot delete record because dependent %{record} exist') # rubocop:disable Style/FormatStringToken
  end
end
