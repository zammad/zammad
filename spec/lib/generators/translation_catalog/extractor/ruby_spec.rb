# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Generators::TranslationCatalog::Extractor::Ruby do
  subject(:extractor_module) { described_class.new }

  let(:filename) { 'myfile' }
  let(:result_strings) do
    extractor_module.extract_from_string(string, filename)
    extractor_module.strings
  end

  context 'with strings to be found' do
    let(:string) do
      <<~'CODE'
        __('__ String')
        __('__ String that only looks like #{interpolation}')
        __("__ double quoted String with '")
        Translation.translate('de-de', '.translate String')
      CODE
    end

    it 'finds the correct strings' do
      # rubocop:disable Lint/InterpolationCheck
      expect(result_strings).to eq(Set['__ String', '__ String that only looks like #{interpolation}', "__ double quoted String with '", '.translate String'])
      # rubocop:enable Lint/InterpolationCheck
    end
  end

  context 'with strings to be ignored' do
    let(:string) do
      <<~'CODE'
        Translation.translate('de-de', dynamic_variable)
        Translation.translate('de-de', "String with #{interpolation}")
        __('')
      CODE
    end

    it 'does not find strings' do
      expect(result_strings).to eq(Set[])
    end
  end
end
