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

  let(:llm_response) { "{s1}\nHallo **Welt**." }

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
    expect(ai_service.execute.content).to eq('<p>Hallo <strong>Welt</strong>.</p>')
  end

  it 'records the service that produced it' do
    expect(ai_service.execute.stored_result.metadata).to include('backend' => 'ai')
  end

  context 'when another service translated the same content' do
    before { described_class.new(context_data: context_data.merge(backend: 'deepl'), locale: target_locale).execute }

    it 'translates it again instead of serving that translation' do
      expect { ai_service.execute }.to change(provider_calls, :size).by(1)
    end

    it 'names itself as the service that produced what is served' do
      expect(ai_service.execute.stored_result.metadata).to include('backend' => 'ai')
    end

    # The row is keyed without the producing service, so the two never hold one each.
    it 'replaces the row of the other service' do
      expect { ai_service.execute }.not_to change(AI::StoredResult, :count)
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

  it 'asks for the content as text with markers' do
    ai_service.execute

    expect(provider_calls.first[:prompt_user]).to eq("{s1}\nHello **world**.")
  end

  it 'asks the provider once' do
    expect { ai_service.execute }.to change(provider_calls, :size).by(1)
  end

  it 'records the text the model was asked for, not the HTML' do
    expect(ai_service.execute.ai_analytics_run.payload).to include('prompt_user' => "{s1}\nHello **world**.")
  end

  it 'tells the model about the markers' do
    ai_service.execute

    expect(provider_calls.first[:prompt_system])
      .to include('{s1}')
      .and include('{1}text{/1}')
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

  context 'with structured HTML' do
    let(:body) do
      <<~HTML.strip
        <h2>Heading</h2>
        <p>A <strong>bold</strong> paragraph with a <a href="https://example.com/doc">link</a>.<br>Second line.</p>
        <ul><li>First item<ol><li>Sub item</li></ol></li></ul>
        <blockquote><p>Quote</p></blockquote>
        <pre><code>bundle exec rspec</code></pre>
        <table><tbody><tr><td colspan="2">Cell</td></tr></tbody></table>
      HTML
    end

    let(:llm_response) do
      <<~TEXT
        {s1}
        Überschrift
        {s2}
        Ein **fetter** Absatz mit einem {1}Link{/1}.
        Zweite Zeile.
        {s3}
        Erster Punkt
        {s4}
        Unterpunkt
        {s5}
        Zitat
        {s6}
        Zelle
      TEXT
    end

    # Nested rather than a flat list of tag names, which cannot tell
    #   <blockquote><p>Zitat</p></blockquote> apart from <blockquote></blockquote><p>Zitat</p>.
    def tag_tree(html)
      element_tree(Nokogiri::HTML5.fragment(html))
    end

    def element_tree(node)
      node.element_children.map { |child| [child.name, element_tree(child)] }
    end

    it 'keeps the structure of the original' do
      expect(tag_tree(ai_service.execute.content)).to eq(tag_tree(body))
    end

    it 'keeps the attributes and the protected content of the original' do
      expect(ai_service.execute.content)
        .to include('href="https://example.com/doc"')
        .and include('colspan="2"')
        .and include('<pre><code>bundle exec rspec</code></pre>')
    end
  end

  context 'when the model answers with HTML' do
    let(:llm_response) { "{s1}\n<b onclick=\"alert(1)\">Hallo</b><script>alert(2)</script>" }

    it 'stores it as text' do
      expect(ai_service.execute.content)
        .to eq('<p>&lt;b onclick="alert(1)"&gt;Hallo&lt;/b&gt;&lt;script&gt;alert(2)&lt;/script&gt;</p>')
    end
  end

  context 'when the answer cannot be rebuilt' do
    let(:body)         { '<p>Read the <a href="https://example.com/doc">guide</a>.</p><p>Thanks!</p>' }
    let(:llm_response) { "{s1}\nLies die Anleitung.\nDanke!" }

    it 'stores the translated text with simplified formatting and the links of the original' do
      expect(ai_service.execute.content)
        .to start_with('<div>Lies die Anleitung.<br>Danke!</div><div><a href="https://example.com/doc"')
    end

    it 'asks the provider once' do
      expect { ai_service.execute }.to change(provider_calls, :size).by(1)
    end
  end

  context 'with HTML without text to translate' do
    let(:body) { '<p><img src="cid:image@example.com"></p><pre>ls -la</pre>' }

    it 'returns no result' do
      expect(ai_service.execute).to be_nil
    end

    it 'does not ask the provider' do
      expect { ai_service.execute }.not_to change(provider_calls, :size)
    end

    it 'saves no analytics run' do
      expect { ai_service.execute }.not_to change(AI::Analytics::Run, :count)
    end
  end

  context 'when the transformation fails' do
    before { allow_any_instance_of(ContentTranslation::Html::Section).to receive(:replace).and_raise(ArgumentError) }

    it 'raises a transformation error instead of the internal one' do
      expect { ai_service.execute }.to raise_error(ContentTranslation::Html::TransformationError, 'The response could not be processed.')
    end

    it 'stores no translation' do
      expect { suppress(ContentTranslation::Html::TransformationError) { ai_service.execute } }
        .not_to change(AI::StoredResult, :count)
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

  context 'when the answer has no text' do
    let(:llm_response) { "{s1}\n{1/}" }

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

    it 'asks for the content without wrapping it' do
      ai_service.execute

      expect(provider_calls.first[:prompt_user]).to eq(body)
    end
  end

  describe '.lookup_version_sql' do
    def sql_version(backend)
      sql = described_class.lookup_version_sql(backend, "ticket_articles.content_type ILIKE '%html%'", 'ticket_articles.body')

      ActiveRecord::Base.connection.select_value(
        "SELECT #{sql} FROM ticket_articles WHERE ticket_articles.id = #{object.id}"
      )
    end

    it 'digests HTML content like the Ruby version' do
      expect(sql_version('ai')).to eq(described_class.lookup_version(context_data, target_locale))
    end

    it 'digests HTML content of another backend like the Ruby version' do
      expect(sql_version('deepl')).to eq(described_class.lookup_version(context_data.merge(backend: 'deepl'), target_locale))
    end

    it 'digests the backend, so another backend does not match' do
      expect(sql_version('libre_translate')).not_to eq(described_class.lookup_version(context_data, target_locale))
    end

    context 'with plain text content' do
      let(:html) { false }
      let(:body) { "Price < 5 & > 3\nSecond line" }

      it 'digests plain text content like the Ruby version' do
        expect(sql_version('ai')).to eq(described_class.lookup_version(context_data, target_locale))
      end
    end

    context 'without a configured backend' do
      let(:context_data) { super().merge(backend: nil) }

      it 'digests a missing backend like the Ruby version' do
        expect(sql_version(nil)).to eq(described_class.lookup_version(context_data, target_locale))
      end
    end
  end
end
