# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'AI text tool result verification', :aggregate_failures, integration: true, required_envs: %w[ZAMMAD_AI_TOKEN], use_vcr: true do # rubocop:disable RSpec/DescribeClass
  shared_examples 'when result verification is performed' do |fixture_path, text_tool_name, options = {}, ai_service_additional_options = {}|
    context "with #{fixture_path.basename}" do
      let(:content)                        { JSON.parse(File.read(fixture_path)) }
      let(:text_tool_execution)            { content['text_tool_execution'] }
      let(:input_text)                     { content['input'].to_s }
      let(:expected_language_code)         { content.dig('expected', 'language') }
      let(:expected_html_markup_present)   { content.dig('expected', 'html_markup_present') }
      let(:text_tool)                      { AI::TextTool.find_by(name: text_tool_name) }
      let(:ai_text_tool_result) do
        AI::Service::TextTool.new(
          context_data:       {
            instruction:        text_tool.instruction,
            fixed_instructions: Setting.get('ai_assistance_text_tools_fixed_instructions'),
            input:              input_text,
            text_tool:,
          },
          additional_options: ai_service_additional_options
        ).execute
      end

      it 'detects expected language and HTML markup' do
        skip 'not relevant for this text tool' if text_tool_execution&.exclude?(text_tool_name)

        language_result = detect_language(ai_text_tool_result.content)

        expect(language_result[:code]).to eq(expected_language_code)

        input_has_html = html_markup?(input_text)
        output_has_html = html_markup?(ai_text_tool_result.content)

        if options[:html_markup_present] || input_has_html
          expect(output_has_html).to be_truthy
        else
          expect(output_has_html).to be_falsey
        end
      end
    end
  end

  fixture_files = if ENV['AI_TEXT_TOOL_RESULT_INPUT_FILE']
                    [Rails.root.join("spec/fixtures/files/ai/text_tool/#{ENV['AI_TEXT_TOOL_RESULT_INPUT_FILE']}")]
                  else
                    Rails.root.glob('spec/fixtures/files/ai/text_tool/*.json')
                  end

  context 'with Zammad AI provider' do
    before do
      setting = Setting.find_by(name: 'ai_provider_config')
      setting.update!(preferences: {})

      setup_ai_provider('zammad_ai', token: ENV['ZAMMAD_AI_TOKEN'])
    end

    context 'when "Rewrite complex section and make it easy to understand" is used' do
      fixture_files.each do |fixture_path|
        include_examples 'when result verification is performed', fixture_path, 'Rewrite complex section and make it easy to understand'
      end
    end

    context 'when "Expand draft into well-written section" is used' do
      fixture_files.each do |fixture_path|
        include_examples 'when result verification is performed', fixture_path, 'Expand draft into well-written section', { html_markup_present: true }
      end
    end

    context 'when "Summarize section to about half its current size" is used' do
      fixture_files.each do |fixture_path|
        include_examples 'when result verification is performed', fixture_path, 'Summarize section to about half its current size'
      end
    end

    context 'when "Fix spelling and grammar" is used' do
      fixture_files.each do |fixture_path|
        include_examples 'when result verification is performed', fixture_path, 'Fix spelling and grammar'
      end
    end

    context 'when mistral model is used' do
      context 'when "Rewrite complex section and make it easy to understand" is used' do
        fixture_files.each do |fixture_path|
          include_examples 'when result verification is performed', fixture_path, 'Rewrite complex section and make it easy to understand', {}, { model: 'mistral-small3.2:24b' }
        end
      end

      context 'when "Expand draft into well-written section" is used' do
        fixture_files.each do |fixture_path|
          include_examples 'when result verification is performed', fixture_path, 'Expand draft into well-written section', { html_markup_present: true }, { model: 'mistral-small3.2:24b' }
        end
      end

      context 'when "Summarize section to about half its current size" is used' do
        fixture_files.each do |fixture_path|
          include_examples 'when result verification is performed', fixture_path, 'Summarize section to about half its current size', {}, { model: 'mistral-small3.2:24b' }
        end
      end

      context 'when "Fix spelling and grammar" is used' do
        fixture_files.each do |fixture_path|
          include_examples 'when result verification is performed', fixture_path, 'Fix spelling and grammar', {}, { model: 'mistral-small3.2:24b' }
        end
      end
    end
  end

  # context 'with Open AI provider' do
  #   before do
  #     setup_ai_provider('open_ai', token: ENV['OPEN_AI_TOKEN'])
  #   end

  #   context 'when "Summarize section to about half its current size" is used' do
  #     fixture_files.each do |fixture_path|
  #       include_examples 'when result verification is performed', fixture_path, 'Summarize section to about half its current size'
  #     end
  #   end
  # end

  # context 'with Mistral provider' do
  #   before do
  #     setup_ai_provider('mistral_ai', token: ENV['MISTRAL_API_KEY'])
  #   end

  #   context 'when "Summarize section to about half its current size" is used' do
  #     fixture_files.each do |fixture_path|
  #       include_examples 'when result verification is performed', fixture_path, 'Summarize section to about half its current size'
  #     end
  #   end
  # end

  def html_markup?(text)
    return false if text&.strip.blank?

    # Simple heuristic: detect presence of an HTML-like opening tag
    text.match?(%r{<\s*[A-Za-z][A-Za-z0-9]*(?:\s|/|>)})
  end

  def detect_language(text)
    text = text.to_s.gsub(%r{<a\b[^>]*>(.*?)</a>}im, '\\1')

    text = text.html2text

    CLD.detect_language(text)
  end
end
