# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Generators::TranslationCatalog::Extractor::Erb do
  subject(:extractor_module) { described_class.new }

  let(:filename) { 'myfile' }
  let(:result_strings) do
    extractor_module.extract_from_string(string, filename)
    extractor_module.strings
  end

  context 'with strings to be found' do
    let(:string) do
      <<~'CODE'
        <%= zt('String') %>
        <%= t('String that only looks like #{interpolation}') %>
        <%= t("Double quoted String with '") %>
      CODE
    end

    it 'finds the correct strings' do
      # rubocop:disable Lint/InterpolationCheck
      expect(result_strings).to eq(Set['String', 'String that only looks like #{interpolation}', "Double quoted String with '"])
      # rubocop:enable Lint/InterpolationCheck
    end
  end

  context 'with strings to be ignored' do
    let(:string) do
      <<~'CODE'
        <%= zt(dynamic_variable) %>
        <%= t("String with #{interpolation}") %>
        <%= t("") %> # should not happen
      CODE
    end

    it 'does not find strings' do
      expect(result_strings).to eq(Set[])
    end
  end

  context 'with strings too long' do
    let(:string) do
      <<~"CODE"
        <%= t("#{'a' * 3001}") %>
      CODE
    end

    it 'raises an error' do
      expect { result_strings }.to raise_error(%r{Found a string that longer than than the allowed 3000 characters})
    end
  end
end
