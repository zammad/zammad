# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ContentTranslation::Text, :aggregate_failures do
  subject(:document) { described_class.new(content, texts:) }

  let(:content) { "Hello John,\n\nread the *guide*." }
  let(:texts)   { { subject: 'Q&A about the {guide}' } }

  def translation(response)
    document.translate(response)
  end

  describe '#to_s' do
    it 'sends each text as a section of its own behind the content, all as they are' do
      expect(document.to_s).to eq("{s1}\nHello John,\n\nread the *guide*.\n{s2}\nQ&A about the {guide}")
    end

    context 'without content' do
      let(:content) { '' }

      it 'sends the texts alone' do
        expect(document.to_s).to eq("{s1}\nQ&A about the {guide}")
      end
    end

    context 'with lines that start like a marker' do
      let(:content) { "Use\n{s2}\nas placeholder, or \\{s3} and {s4} inside." }
      let(:texts)   { { subject: '{s2} Template example' } }

      it 'sends them with a backslash in front, and marker-like words inside a line as they are' do
        expect(document.to_s).to eq("{s1}\nUse\n\\{s2}\nas placeholder, or \\{s3} and {s4} inside.\n{s2}\n\\{s2} Template example")
      end
    end
  end

  # What the parser makes of an answer that keeps every character: the texts as they were given.
  describe 'an answer identical to what was sent' do
    [
      '{s2} Template example',
      '{s1} Template example',
      '{s9} Template example',
      '{ s2 } Template example',
      '\\{s2} Template example',
      '\\\\{s2} Template example',
      'Template {s2} example \\{s2}',
      'C:\\Users\\{s2}',
    ].each do |subject|
      context "with the text #{subject.inspect}" do
        let(:texts) { { subject: } }

        it 'gives back the content and the text' do
          expect(translation(document.to_s)).to eq(content)
          expect(document.translated_texts).to eq(subject:)
        end
      end
    end

    [
      "Use\n{s2}\nas placeholder.",
      "{s1} first line\n{s2} second line\n{s3} third line",
      "\\{s2} escaped already\n\\\\{s2} twice",
      "C:\\Users\\name\n\\\\server\\share\\{s2}",
      '  {s2} indented',
    ].each do |body|
      context "with the content #{body.inspect}" do
        let(:content) { body }

        it 'gives back the content and the text' do
          expect(translation(document.to_s)).to eq(body.strip)
          expect(document.translated_texts).to eq(texts)
        end
      end
    end

    context 'without content' do
      let(:content) { '' }
      let(:texts)   { { subject: '{s1} Template example' } }

      it 'gives back the text' do
        expect(translation(document.to_s)).to eq('')
        expect(document.translated_texts).to eq(texts)
      end
    end
  end

  describe '#translate' do
    it 'keeps the translations of the texts apart from the content' do
      expect(translation("{s1}\nHallo John,\n\nlies die *Anleitung*.\n{s2}\nFragen zur {Anleitung}"))
        .to eq("Hallo John,\n\nlies die *Anleitung*.")
      expect(document.translated_texts).to eq(subject: 'Fragen zur {Anleitung}')
    end

    it 'accepts blank lines and whitespace around the sections' do
      expect(translation("\n { s1 } \n\nHallo John.\n\n{s2}\nFragen zur Anleitung\n")).to eq('Hallo John.')
      expect(document.translated_texts).to eq(subject: 'Fragen zur Anleitung')
    end

    it 'accepts the markers on the line of their text' do
      expect(translation("{s1} Hallo John.\n{s2} Fragen zur Anleitung")).to eq('Hallo John.')
      expect(document.translated_texts).to eq(subject: 'Fragen zur Anleitung')
    end

    it 'takes the content also without its own marker' do
      expect(translation("Hallo John.\n{s2}\nFragen zur Anleitung")).to eq('Hallo John.')
      expect(document.translated_texts).to eq(subject: 'Fragen zur Anleitung')
    end

    it 'keeps a marker-like word inside a line as text' do
      expect(translation("{s1}\nDie Vorlage nutzt {s2}.\n{s2}\nFragen zu {s2} und {s9}")).to eq('Die Vorlage nutzt {s2}.')
      expect(document.translated_texts).to eq(subject: 'Fragen zu {s2} und {s9}')
    end

    it 'takes the backslash off a translated line that starts like a marker' do
      expect(translation("{s1}\nDie Vorlage nutzt\n\\{s2}\nals Platzhalter.\n{s2}\n\\{s2} Vorlagenbeispiel")).to eq("Die Vorlage nutzt\n{s2}\nals Platzhalter.")
      expect(document.translated_texts).to eq(subject: '{s2} Vorlagenbeispiel')
    end

    # The last marker is the one of the texts, which are behind the content.
    it 'keeps such a line of the content also when the model dropped its backslash' do
      expect(translation("{s1}\nDie Vorlage nutzt\n{s2}\nals Platzhalter.\n{s2}\nFragen")).to eq("Die Vorlage nutzt\n{s2}\nals Platzhalter.")
      expect(document.translated_texts).to eq(subject: 'Fragen')
    end

    # Nothing says where the content ends, and a guess could move content into the text.
    it 'takes all of an answer without the marker of the texts as content' do
      expect(translation("{s1}\nHallo John.\nFragen zur Anleitung")).to eq("Hallo John.\nFragen zur Anleitung")
      expect(document.translated_texts).to eq({})
    end

    # The escaped line is no marker, so it cannot stand in for the missing one of the texts.
    it 'takes all of an answer as content that has a line like a marker, but no marker of the texts' do
      expect(translation("{s1}\nNutze\n\\{s2}\nals Platzhalter.\nFrage")).to eq("Nutze\n{s2}\nals Platzhalter.\nFrage")
      expect(document.translated_texts).to eq({})
    end

    context 'without content' do
      let(:content) { '' }

      it 'answers with empty content and the translated texts' do
        expect(translation("{s1}\nFragen zur Anleitung")).to eq('')
        expect(document.translated_texts).to eq(subject: 'Fragen zur Anleitung')
      end

      it 'takes an answer without the marker for the text' do
        translation('Fragen zur Anleitung')

        expect(document.translated_texts).to eq(subject: 'Fragen zur Anleitung')
      end
    end
  end
end
