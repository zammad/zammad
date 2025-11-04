# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Service::TextTool, required_envs: %w[OPEN_AI_TOKEN ZAMMAD_AI_TOKEN], use_vcr: true do
  subject(:ai_service) { described_class.new(current_user:, context_data:) }

  let(:current_user) { create(:user) }
  let(:text_tool)    { create(:ai_text_tool) }

  let(:context_data) do
    {
      instruction:        'You are a text correction AI assistant.

You are given a text, most likely in HTML format.

Your task is to correct:
- spelling
- grammar
- punctuation
- and sentence-structure errors.

You have to follow these rules:
- Detect the input language and make sure the corrected text is using the same language.
- Correct only the text content, neither the HTML tags nor the given structure.
- Preserve all HTML tags and formatting exactly as in the input.',
      fixed_instructions: Setting.get('ai_assistance_text_tools_fixed_instructions'),
      input:              'I ma Nicole Braun.',
      text_tool:,
    }
  end

  context 'when service is executed with OpenAI as provider' do
    before do
      setup_ai_provider('open_ai', token: ENV['OPEN_AI_TOKEN'])
    end

    it 'check that grammar is correct' do
      result = ai_service.execute
      expect(result.content).to include('I am Nicole Braun.')
    end
  end

  context 'when service is executed with ZammadAI as provider' do
    before do
      setup_ai_provider('zammad_ai', token: ENV['ZAMMAD_AI_TOKEN'])
    end

    it 'check that grammar is correct' do
      result = ai_service.execute
      expect(result.content).to include('I am Nicole Braun.')
    end
  end

  context 'when result transformation is performed' do
    before do
      setting = Setting.find_by(name: 'ai_provider_config')
      setting.update!(preferences: {})

      setup_ai_provider('zammad_ai', token: ENV['ZAMMAD_AI_TOKEN'])
    end

    context 'when neither prompt nor result contain paragraphs but have line breaks' do
      subject(:ai_service) do
        described_class.new(
          context_data: {
            instruction:        'instruction',
            fixed_instructions: 'fixed',
            input:              prompt_input,
            text_tool:          text_tool,
          },
          prompt_user:  prompt_input,
        )
      end

      let(:prompt_input) { "Line one\nLine two\n\nLine three" }

      it 'converts line breaks to <br>' do
        allow(ai_service).to receive(:ask_provider).and_return("A\nB\n\nC")

        result = ai_service.execute
        expect(result.content).to eq('A<br>B<br><br>C')
      end
    end

    context 'when prompt contains paragraphs but result does not' do
      subject(:ai_service) do
        described_class.new(
          context_data: {
            instruction:        'instruction',
            fixed_instructions: 'fixed',
            input:              prompt_input,
            text_tool:          text_tool,
          },
          prompt_user:  prompt_input,
        )
      end

      let(:prompt_input) { '<p>Some</p><p>Thing</p>' }

      it 'wraps blank-line separated paragraphs in <p> tags' do
        allow(ai_service).to receive(:ask_provider).and_return("Para1\n\nPara2")

        result = ai_service.execute
        expect(result.content).to eq('<p>Para1</p><p>Para2</p>')
      end
    end
  end

  context 'when rendering the user prompt template' do
    let(:input) { '<div>hello</div><div data-signature="true"><div>signature inner<div>signature inner 2</div></div></div><div class="x">bye</div>' }

    it 'converts non-signature divs to <p> but preserves signature block' do
      service = described_class.new(
        context_data: {
          instruction:        'instruction',
          fixed_instructions: 'fixed',
          input:              input,
          text_tool:          text_tool,
        }
      )

      rendered = service.send(:prompt_user)
      expect(rendered).to eq('<p>hello</p><div data-signature="true"><div>signature inner<div>signature inner 2</div></div></div><p class="x">bye</p>')
    end
  end
end
