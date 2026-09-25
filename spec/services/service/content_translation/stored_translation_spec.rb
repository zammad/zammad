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

  it 'finds nothing while nothing is stored' do
    expect(find).to be_nil
  end
end
