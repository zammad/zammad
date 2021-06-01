# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SignatureDetection do
  describe '.find_signature' do
    context 'when given an array of hashes' do
      let(:messages) do
        raw_message_files.map do |f|
          { content: File.read(f), content_type: content_type }
        end
      end

      context 'with plain text messages in their :content keys (sample input 1)' do
        let(:content_type) { 'text/plain' }

        let(:raw_message_files) do
          [
            Rails.root.join('test/data/email_signature_detection/client_a_1.txt'),
            Rails.root.join('test/data/email_signature_detection/client_a_2.txt'),
            Rails.root.join('test/data/email_signature_detection/client_a_3.txt')
          ]
        end

        it 'returns the first 5–10-line substring they share in common' do
          expect(described_class.find_signature(messages)).to eq(<<~SIG.chomp)

            Mit freundlichen Grüßen

            Bob Smith
            Berechtigungen und dez. Department
            ________________________________

            Musik AG
            Berechtigungen und dez. Department (ITPBM)
            Kastanien 2
          SIG
        end
      end

      context 'with plain text messages in their :content keys (sample input 2)' do
        let(:content_type) { 'text/plain' }

        let(:raw_message_files) do
          [
            Rails.root.join('test/data/email_signature_detection/client_b_1.txt'),
            Rails.root.join('test/data/email_signature_detection/client_b_2.txt'),
            Rails.root.join('test/data/email_signature_detection/client_b_3.txt')
          ]
        end

        it 'returns the first 5–10-line substring they share in common' do
          expect(described_class.find_signature(messages)).to eq(<<~SIG.chomp)

            Freundliche Grüße

            Günter Lässig
            Lokale Daten

            Music GmbH
            Baustraße 123, 12345 Max City
            Telefon 0123 5432114
            Telefax 0123 5432139
          SIG
        end
      end

      context 'with HTML messages in their :content keys' do
        let(:content_type) { 'text/html' }

        let(:raw_message_files) do
          [
            Rails.root.join('test/data/email_signature_detection/client_c_1.html'),
            Rails.root.join('test/data/email_signature_detection/client_c_2.html'),
            Rails.root.join('test/data/email_signature_detection/client_c_3.html')
          ]
        end

        it 'converts messages (via #html2text) then returns the first 5–10-line substring they share in common' do
          expect(described_class.find_signature(messages)).to eq(<<~SIG.chomp)

            ChristianSmith
            Technik

            Tel: +49 12 34 56 78 441
            Fax: +49 12 34 56 78 499
            Email: Christian.Smith@example.com
            Web: www.example.com
            ABC KFZ- und Flugzeug B.V. & Co. KG
            Hauptverwaltung
          SIG
        end
      end
    end

    context 'when input messages do not share 5-line common substrings' do
      let(:messages) do
        Array.new(2) { { content: <<~RAW, content_type: 'text/plain' } }
          Lorem ipsum dolor sit amet, consectetur adipiscing elit.
          Ut ut tincidunt nunc. Sed mattis aliquam tellus sit amet lacinia.
          Mauris fermentum dictum aliquet.
          Nam ex risus, gravida et ornare ut, mollis non sapien.
        RAW
      end

      it 'doesn’t break' do
        expect { described_class.find_signature(messages) }.not_to raise_error
      end
    end
  end

  describe '.find_signature_line' do
    context 'when given a plain text message' do
      let(:content_type) { 'text/plain' }
      let(:content) { File.read(Rails.root.join('test/data/email_signature_detection/client_a_1.txt')) }

      context 'and a substring it contains' do
        let(:signature) { <<~SIG.chomp }

          Mit freundlichen Grüßen

          Bob Smith
          Berechtigungen und dez. Department
          ________________________________

          Musik AG
          Berechtigungen und dez. Department (ITPBM)
          Kastanien 2
        SIG

        it 'returns the line of the message where the signature begins' do
          expect(described_class.find_signature_line(signature, content, content_type)).to eq(10)
        end
      end
    end

    context 'when given an HTML message' do
      let(:content_type) { 'text/html' }
      let(:content) { File.read(Rails.root.join('test/data/email_signature_detection/example1.html')) }

      context 'and a substring it contains' do
        let(:signature) { <<~SIG.chomp }
          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          Bob Smith
          ABC Organisation

          EXAMPLE IT-Service GmbH
          Dorten 5 F&E
          12345 Da / Germany
          Phone: +49 (0) 1234 567 890 / +49 (0) 1234 567 891
          Fax:     +49 (0) 1234 567 892
        SIG

        it 'converts messages (via #html2text) then returns the line of the message where the signature begins' do
          expect(described_class.find_signature_line(signature, content, content_type)).to eq(11)
        end
      end
    end
  end

  describe '.rebuild_all_articles' do
    context 'when a user exists with a recorded signature' do
      let!(:customer) { create(:customer, preferences: { signature_detection: "\nbar" }) }

      context 'and multiple articles exist for that customer' do
        let!(:articles) do
          [create(:ticket_article, created_by_id: customer.id, body: "foo\nfoo\nbar"),
           create(:ticket_article, created_by_id: customer.id, body: "foo\nbar")]
        end

        it 'updates the signature-line data of all articles' do
          expect { described_class.rebuild_all_articles }
            .to change { articles.first.reload.preferences[:signature_detection] }.to(3)
            .and change { articles.second.reload.preferences[:signature_detection] }.to(2)
        end
      end
    end
  end
end
