# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Text::QuoteRemover, :aggregate_failures do
  shared_examples 'removes quoted parts from fixture' do |fixture_path|
    context "with #{fixture_path.basename}" do
      let(:input_text)    { File.read(fixture_path) }
      let(:expected_text) { File.read(fixture_path.to_s.sub('-input.txt', '-expected.txt')) }

      it 'removes the quoted parts' do
        result = described_class.new(text: input_text).remove

        expect(result).to eq(expected_text)
      end
    end
  end

  shared_examples 'removes signatures from fixture' do |fixture_path|
    context "with #{fixture_path.basename}" do
      let(:input_text)    { File.read(fixture_path) }
      let(:expected_text) { File.read(fixture_path.to_s.sub('-input.txt', '-expected.txt')) }

      it 'removes the signatures' do
        result = described_class.new(text: input_text, remove_signatures: true).remove

        expect(result).to eq(expected_text)
      end
    end
  end

  describe 'quote removal' do
    fixture_path = 'spec/fixtures/files/text/quote_remover/'

    fixture_files = if ENV['REMOVE_QUOTE_RESULT_INPUT_FILE']
                      [Rails.root.join("#{fixture_path}#{ENV['REMOVE_QUOTE_RESULT_INPUT_FILE']}")]
                    else
                      Rails.root.glob("#{fixture_path}*-input.txt")
                    end

    fixture_files.each do |file_path|
      include_examples 'removes quoted parts from fixture', file_path
    end
  end

  describe 'signature removal' do
    describe 'with remove_signatures: true' do
      fixture_path = 'spec/fixtures/files/text/quote_remover/signature/'

      fixture_files = if ENV['REMOVE_SIGNATURE_RESULT_INPUT_FILE']
                        [Rails.root.join("#{fixture_path}#{ENV['REMOVE_SIGNATURE_RESULT_INPUT_FILE']}")]
                      else
                        Rails.root.glob("#{fixture_path}*-input.txt")
                      end

      fixture_files.each do |file_path|
        include_examples 'removes signatures from fixture', file_path
      end
    end
  end
end
