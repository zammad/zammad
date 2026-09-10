# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Feature::Translate do
  subject(:ai_service) { described_class.new(context_data:, locale: target_locale) }

  let(:target_locale) { 'de-de' }
  let(:html)          { true }
  let(:body)          { '<p>Hello <strong>world</strong>.</p>' }

  # Any object can hold a translation; a ticket article is the first caller's object.
  let(:object) { create(:ticket_article, body:, content_type: html ? 'text/html' : 'text/plain') }

  let(:context_data) do
    {
      object:,
      body:    object.body,
      html:,
      backend: 'ai',
    }
  end

  let(:llm_response) { '<p>Hallo <strong>Welt</strong>.</p>' }

  # Every prompt pair the provider was asked with — the size doubles as the call count.
  let(:provider_calls) { [] }

  before do
    setup_ai_provider('zammad_ai')

    allow_any_instance_of(AI::Provider::ZammadAI).to receive(:ask) do |_provider, **prompts|
      provider_calls << prompts
      llm_response
    end
  end

  it 'returns the translated content' do
    expect(ai_service.execute.content).to eq(llm_response)
  end

  it 'records the service that produced it' do
    expect(ai_service.execute.stored_result.metadata).to include('backend' => 'ai')
  end

  context 'when another service translated the same content' do
    before { described_class.new(context_data: context_data.merge(backend: 'deepl'), locale: target_locale).execute }

    it 'reuses its translation' do
      expect { ai_service.execute }.not_to change(provider_calls, :size)
    end

    it 'keeps naming the service that produced it' do
      expect(ai_service.execute.stored_result.metadata).to include('backend' => 'deepl')
    end
  end

  it 'saves an analytics run' do
    expect { ai_service.execute }.to change(AI::Analytics::Run, :count).by(1)
  end

  it 'relates the analytics run to the translated object' do
    expect(ai_service.execute.ai_analytics_run.related_object).to eq(object)
  end

  it 'asks for a translation into the target locale' do
    ai_service.execute

    expect(provider_calls.first[:prompt_system]).to include('Deutsch - German', 'de-de')
  end

  it 'asks for the content without wrapping it' do
    ai_service.execute

    expect(provider_calls.first[:prompt_user]).to eq(body)
  end

  it 'tells the model that the content is HTML' do
    ai_service.execute

    expect(provider_calls.first[:prompt_system])
      .to include('HTML format')
      .and include('<blockquote>')
      .and not_include('plain text')
  end

  context 'when a translation is already stored' do
    before { ai_service.execute }

    it 'serves a second request for the same object and locale from the store' do
      expect { described_class.new(context_data:, locale: target_locale).execute }
        .not_to change(provider_calls, :size)
    end

    it 'keeps serving the stored translation after the object was only touched' do
      object.touch

      expect { described_class.new(context_data:, locale: target_locale).execute }
        .not_to change(provider_calls, :size)
    end

    it 'requests a translation for another target locale' do
      expect { described_class.new(context_data:, locale: 'en-us').execute }
        .to change(provider_calls, :size).by(1)
    end

    it 'requests a translation for another object with the same content' do
      other_context_data = context_data.merge(object: create(:ticket_article, body:))

      expect { described_class.new(context_data: other_context_data, locale: target_locale).execute }
        .to change(provider_calls, :size).by(1)
    end

    it 'requests a translation after the content type changed' do
      changed_context_data = context_data.merge(html: false)

      expect { described_class.new(context_data: changed_context_data, locale: target_locale).execute }
        .to change(provider_calls, :size).by(1)
    end

    it 'requests a translation after the content changed' do
      changed_context_data = context_data.merge(body: '<p>Hello <strong>there</strong>.</p>')

      expect { described_class.new(context_data: changed_context_data, locale: target_locale).execute }
        .to change(provider_calls, :size).by(1)
    end
  end

  # Preserving the structure of the content has two halves: the model has to return it, which the
  #   prompt asks for and its evaluation answers, and the sanitizer must not take it away again.
  #   The second half is the one that would break the promise silently, so it is pinned here.
  context 'when the model returns structured HTML' do
    let(:llm_response) do
      <<~HTML.strip
        <h2>Uberschrift</h2>
        <p>Ein <strong>fetter</strong> Absatz mit einem <a href="https://example.com/doc">Link</a>.<br>Zweite Zeile.</p>
        <ul><li>Erster Punkt<ol><li>Unterpunkt</li></ol></li></ul>
        <blockquote><p>Zitat</p></blockquote>
        <pre><code>bundle exec rspec</code></pre>
        <table><thead><tr><th>Kopf</th></tr></thead><tbody><tr><td colspan="2">Zelle</td></tr></tbody></table>
      HTML
    end

    # Nested rather than a flat list of tag names, which cannot tell
    #   <blockquote><p>Zitat</p></blockquote> apart from <blockquote></blockquote><p>Zitat</p>.
    def tag_tree(html)
      element_tree(Nokogiri::HTML5.fragment(html))
    end

    def element_tree(node)
      node.element_children.map { |child| [child.name, element_tree(child)] }
    end

    it 'stores the structure of the answer unchanged' do
      expect(tag_tree(ai_service.execute.content)).to eq(tag_tree(llm_response))
    end

    it 'stores the attributes that carry structure' do
      expect(ai_service.execute.content)
        .to include('href="https://example.com/doc"')
        .and include('colspan="2"')
    end
  end

  context 'when the model returns unsafe HTML' do
    let(:llm_response) { '<p onclick="alert(1)">Hallo</p><script>alert(2)</script>' }

    it 'stores the content without script tags and event handlers' do
      stored_content = ai_service.execute.content

      expect(stored_content)
        .to include('Hallo')
        .and not_include('onclick')
        .and not_include('<script')
    end
  end

  context 'when the sanitizer cannot process the answer' do
    before do
      allow(HtmlSanitizer).to receive(:strict).and_return(HtmlSanitizer::UNPROCESSABLE_HTML_MSG)
    end

    it 'stores no translation' do
      expect { ai_service.execute }.not_to change(AI::StoredResult, :count)
    end

    it 'returns no result' do
      expect(ai_service.execute).to be_nil
    end
  end

  context 'when nothing is left after sanitizing' do
    let(:llm_response) { '<script>alert(1)</script>' }

    it 'stores no translation' do
      expect { ai_service.execute }.not_to change(AI::StoredResult, :count)
    end

    it 'returns no result' do
      expect(ai_service.execute).to be_nil
    end
  end

  context 'when the model returns nothing' do
    let(:llm_response) { '' }

    it 'stores no translation' do
      expect { ai_service.execute }.not_to change(AI::StoredResult, :count)
    end

    it 'returns no result' do
      expect(ai_service.execute).to be_nil
    end
  end

  context 'with plain text content' do
    let(:html)         { false }
    let(:body)         { "Price < 5 & > 3\nSecond line" }
    let(:llm_response) { "Preis < 5 & > 3\nZweite Zeile" }

    it 'tells the model that the content is plain text' do
      ai_service.execute

      expect(provider_calls.first[:prompt_system])
        .to include('simple plain text')
        .and not_include('<blockquote>')
    end

    it 'returns the content unchanged by the HTML sanitizer' do
      expect(ai_service.execute.content).to eq("Preis < 5 & > 3\nZweite Zeile")
    end
  end
end
