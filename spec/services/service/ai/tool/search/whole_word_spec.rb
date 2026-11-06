# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Search::WholeWord, :aggregate_failures do
  describe '.words' do
    it 'takes the words without the quotes, stars and punctuation around them, once each' do
      expect(described_class.words(' "door-03.example.org"? SRM_FAILURE* srm_failure, (v2.1) ')).to eq(%w[door-03.example.org SRM_FAILURE v2.1])
      expect(described_class.words(' "" * ')).to eq([])
    end
  end

  describe '.in?' do
    it 'finds the word itself, in any case and before punctuation' do
      expect(described_class.in?('Error err-4032 means a timeout.', 'ERR-4032')).to be(true)
      expect(described_class.in?('Look up ERR-4032.', 'ERR-4032')).to be(true)
      expect(described_class.in?('(ERR-4032)', 'ERR-4032')).to be(true)
    end

    it 'does not take a longer word that begins or ends with it for it' do
      expect(described_class.in?('ERR-40321 means a timeout.', 'ERR-4032')).to be(false)
      expect(described_class.in?('MAIL-ERR-4032 means a timeout.', 'ERR-4032')).to be(false)
      expect(described_class.in?('Update to v2.1.3 first.', 'v2.1')).to be(false)
      expect(described_class.in?('SSL_ERROR_SYSCALL', 'SSL_ERROR')).to be(false)
      expect(described_class.in?('Restarted the service.', 'restart')).to be(false)
    end

    it 'keeps a name with several separators in a row whole' do
      expect(described_class.in?('node--backup failed', 'node')).to be(false)
      expect(described_class.in?('node--backup failed', 'backup')).to be(false)
      expect(described_class.in?('node--backup failed', 'node--backup')).to be(true)
      expect(described_class.in?('MAIL--ERR-4032 means a timeout.', 'ERR-4032')).to be(false)
      expect(described_class.in?('Restart the node. Then wait.', 'node')).to be(true)
      expect(described_class.in?("-- \nERR-4032 in the signature", 'ERR-4032')).to be(true)
    end

    it 'searches a text with other than ASCII letters, for words with and without them' do
      expect(described_class.in?('Fehler SRM_FAILURE für Kunde', 'SRM_FAILURE')).to be(true)
      expect(described_class.in?('Das Café ist zu.', 'café')).to be(true)
      expect(described_class.in?('ÄRGER mit dem Drucker', 'ärger')).to be(true)
      expect(described_class.in?('Cafés sind zu.', 'café')).to be(false)
    end

    it 'tells a version on its own from one inside a longer one, also in a text with characters beyond ASCII' do
      expect(described_class.in?('Zammad 7.3 release date', '7.3')).to be(true)
      expect(described_class.in?('Für Zammad 7.3 gibt es noch kein Datum.', '7.3')).to be(true)
      expect(described_class.in?('Behoben in v7.3.1 für alle Kunden.', '7.3')).to be(false)
      expect(described_class.in?('Behoben in 7.3.1.', '7.3')).to be(false)
      expect(described_class.in?('Seit 17.3 läuft es.', '7.3')).to be(false)
      expect(described_class.in?('Fehler err-4032 beim Abgleich.', 'ERR-4032')).to be(true)
    end
  end
end
