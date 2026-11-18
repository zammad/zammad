# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# No AI provider is set up anywhere here on purpose: the store is what a translation backend
# without an AI feature behind it uses.
RSpec.describe Service::ContentTranslation::StoredTranslation do
  let(:object)  { create(:ticket_article, body: content, content_type: 'text/html') }
  let(:locale)  { Locale.find_by(locale: 'de-de') }
  let(:content) { '<p>Hello world.</p>' }
  let(:html)    { true }
  let(:backend) { 'libre_translate' }

  # What identifies the row, so an example can vary one part of it.
  let(:key) { { object:, locale:, content:, html:, backend: } }

  def save(translation: '<p>Hallo Welt.</p>', **overrides)
    described_class.save(**key, **overrides, translation:)
  end

  def find(**overrides)
    described_class.find(**key, **overrides)
  end

  describe '.save' do
    it 'stores the translation' do
      expect(save.content).to eq('<p>Hallo Welt.</p>')
    end

    it 'records the service that produced it' do
      expect(save.metadata).to include('backend' => 'libre_translate')
    end

    it 'keys the row by the translate identifier, the object and the target locale' do
      expect(save).to have_attributes(identifier: 'translate', related_object: object, locale:)
    end

    it 'keeps what the producer reports about itself' do
      expect(save(metadata: { 'model' => 'small' }).metadata)
        .to include('model' => 'small', 'backend' => 'libre_translate')
    end

    it 'relates no analytics run for a backend that records none' do
      expect(save.ai_analytics_run).to be_nil
    end

    it 'relates a given analytics run' do
      run = create(:ai_analytics_run)

      expect(save(analytics_run: run).ai_analytics_run).to eq(run)
    end

    # The row is keyed without the producing service, so the second service overwrites the first
    # rather than both being kept.
    it 'replaces what another service stored for the same object and locale' do
      save(backend: 'ai', translation: '<p>Von der KI.</p>')

      expect { save }.not_to change(AI::StoredResult, :count)
    end

    # Such a row has to stay what every row was before extra texts were translated.
    it 'adds nothing to the metadata without extra texts' do
      expect(save.metadata).to eq('backend' => 'libre_translate')
    end

    context 'with extra texts translated along with the content' do
      let(:extra_texts) { { subject: 'Printer broken' } }

      it 'keeps each translation with the digest of its text' do
        expect(save(extra_texts:, extra_translations: { subject: 'Drucker defekt' }).metadata).to eq(
          'backend'     => 'libre_translate',
          'extra_texts' => { 'subject' => { 'version' => Digest::SHA256.hexdigest('Printer broken'), 'content' => 'Drucker defekt' } },
        )
      end

      # The row is still found by its content alone, whatever happens to the extra texts.
      it 'leaves the content and its digest as they are' do
        expect(save(extra_texts:, extra_translations: { subject: 'Drucker defekt' }))
          .to have_attributes(content: '<p>Hallo Welt.</p>', version: described_class.version(content, html, backend))
      end

      it 'keeps no blank translation' do
        expect(save(extra_texts:, extra_translations: { subject: '' }).metadata).to eq('backend' => 'libre_translate')
      end
    end

    context 'when another request stored the same translation first' do
      let(:winner) { save }

      # Simulated, because the collision itself needs two database connections: the losing request
      # looked the row up before the winning one committed, so it builds a new one.
      before do
        winner

        allow(AI::StoredResult).to receive(:find_or_initialize_by)
          .and_return(AI::StoredResult.new(**described_class.lookup_attributes(object, locale)))
      end

      it 'serves what the other request stored' do
        expect(save).to eq(winner)
      end

      it 'stores no second row' do
        expect { save }.not_to change(AI::StoredResult, :count)
      end
    end
  end

  describe '.version' do
    # Rows stored before the AI backend had its own HTML format have to keep matching.
    it 'digests the content of other backends as before', :aggregate_failures do
      expect(described_class.version(content, true, 'libre_translate')).to eq(Digest::SHA256.hexdigest("libre_translate\ntrue\n#{content}"))
      expect(described_class.version(content, true, 'deepl')).to eq(Digest::SHA256.hexdigest("deepl\ntrue\n#{content}"))
      expect(described_class.version('Hello world.', false, 'ai')).to eq(Digest::SHA256.hexdigest("ai\nfalse\nHello world."))
    end

    it 'digests HTML of the AI backend with its format, so translations of the raw HTML are not served' do
      expect(described_class.version(content, true, 'ai')).to eq(Digest::SHA256.hexdigest("ai\n#{described_class::AI_HTML_FORMAT}\n#{content}"))
    end
  end

  describe '.find' do
    before { save }

    it 'serves what this service stored' do
      expect(find.content).to eq('<p>Hallo Welt.</p>')
    end

    it 'does not serve what another service stored' do
      expect(find(backend: 'ai')).to be_nil
    end

    it 'does not serve the translation of content that changed since' do
      expect(find(content: '<p>Hello there.</p>')).to be_nil
    end

    it 'does not serve the translation of the same content in another content type' do
      expect(find(html: false)).to be_nil
    end

    it 'does not serve the translation into another locale' do
      expect(find(locale: Locale.find_by(locale: 'en-us'))).to be_nil
    end

    it 'does not serve the translation of another object with the same content' do
      expect(find(object: create(:ticket_article, body: content))).to be_nil
    end
  end

  describe '.extra_translations' do
    let(:extra_texts) { { subject: 'Printer broken' } }
    let(:record)      { save(extra_texts:, extra_translations: { subject: 'Drucker defekt' }) }

    it 'serves the translation of a text that is still the same' do
      expect(described_class.extra_translations(record, extra_texts)).to eq(subject: 'Drucker defekt')
    end

    it 'serves none for a text that changed since' do
      expect(described_class.extra_translations(record, { subject: 'Printer repaired' })).to eq({})
    end

    # Stored before extra texts were translated, or for an object that had none then.
    it 'serves none from a row that holds none' do
      expect(described_class.extra_translations(save, extra_texts)).to eq({})
    end
  end

  it 'finds nothing while nothing is stored' do
    expect(find).to be_nil
  end
end
