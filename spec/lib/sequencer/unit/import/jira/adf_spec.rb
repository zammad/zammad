# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Jira::Adf do
  subject(:converter) { Class.new { include Sequencer::Unit::Import::Jira::Adf }.new }

  describe '#adf_to_text' do
    it 'returns an empty string for blank input' do
      expect(converter.adf_to_text(nil)).to eq('')
    end

    it 'extracts plain text from a paragraph' do
      node = {
        'type'    => 'doc',
        'content' => [
          {
            'type'    => 'paragraph',
            'content' => [{ 'type' => 'text', 'text' => 'Hello world' }],
          },
        ],
      }

      expect(converter.adf_to_text(node).strip).to eq('Hello world')
    end

    it 'joins multiple block nodes with newlines' do
      node = {
        'type'    => 'doc',
        'content' => [
          { 'type' => 'paragraph', 'content' => [{ 'type' => 'text', 'text' => 'Line 1' }] },
          { 'type' => 'paragraph', 'content' => [{ 'type' => 'text', 'text' => 'Line 2' }] },
        ],
      }

      expect(converter.adf_to_text(node)).to eq("Line 1\nLine 2\n")
    end

    it 'renders mentions, links and hard breaks' do
      node = {
        'type'    => 'paragraph',
        'content' => [
          { 'type' => 'mention', 'attrs' => { 'text' => 'Jane Doe' } },
          { 'type' => 'hardBreak' },
          { 'type' => 'inlineCard', 'attrs' => { 'url' => 'https://example.com' } },
        ],
      }

      expect(converter.adf_to_text(node)).to eq("@Jane Doe\nhttps://example.com\n")
    end
  end
end
