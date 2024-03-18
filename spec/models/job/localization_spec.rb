# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Job > Localization' do # rubocop:disable RSpec/DescribeClass
  let(:job) { create(:job, perform: perform, localization: locale, timezone: time_zone) }

  let(:time_zone) { 'Europe/Berlin' }
  let(:locale)    { 'de-de' }

  let(:perform) do
    {
      'article.note' => {
        'subject'  => 'Test subject note',
        'internal' => 'true',
        'body'     => body,
      },
    }
  end

  let(:body) do
    <<~BODY
      Lieber Absender, wir haben Ihre Anfrage erhalten und werden sie so schnell wie möglich bearbeiten.

      Daten:
      * Status: \#{t(ticket.state.name)}
      * Priorität: \#{t(ticket.priority.name)}
      * Erstellt am: \#{ticket.created_at}
    BODY
  end

  context 'when locale is set' do
    before do
      Translation.sync_locale_from_po(locale)
      Setting.set('locale_default', 'el')
      Setting.set('timezone_default', 'Africa/Abidjan')

      job
    end

    it 'creates a note with translated content' do
      ticket = create(:ticket, state_id: Ticket::State.find_by(name: 'open').id, priority_id: Ticket::Priority.lookup(name: '3 high').id)
      job.run(true)

      expect(Ticket::Article.last.body).to eq(<<~BODY)
        Lieber Absender, wir haben Ihre Anfrage erhalten und werden sie so schnell wie möglich bearbeiten.

        Daten:
        * Status: offen
        * Priorität: 3 hoch
        * Erstellt am: #{ticket.created_at.in_time_zone(time_zone).strftime('%d.%m.%Y %H:%M (Europe/Berlin)')}
      BODY
    end

    context 'when timezone is set' do
      let(:time_zone) { 'Europe/London' }

      it 'creates a note with translated content' do
        ticket = create(:ticket, state_id: Ticket::State.find_by(name: 'open').id, priority_id: Ticket::Priority.lookup(name: '3 high').id)
        job.run(true)

        expect(Ticket::Article.last.body).to eq(<<~BODY)
          Lieber Absender, wir haben Ihre Anfrage erhalten und werden sie so schnell wie möglich bearbeiten.

          Daten:
          * Status: offen
          * Priorität: 3 hoch
          * Erstellt am: #{ticket.created_at.in_time_zone(time_zone).strftime('%d.%m.%Y %H:%M (Europe/London)')}
        BODY
      end
    end

    context 'when locale and timezone are not set' do
      let(:time_zone) { nil }
      let(:locale)    { nil }

      it 'creates a note with untranslated content' do
        ticket = create(:ticket, state_name: 'open', priority_name: '3 high')
        job.run(true)

        expect(Ticket::Article.last.body).to eq(<<~BODY)
          Lieber Absender, wir haben Ihre Anfrage erhalten und werden sie so schnell wie möglich bearbeiten.

          Daten:
          * Status: open
          * Priorität: 3 high
          * Erstellt am: #{ticket.created_at.in_time_zone(time_zone).strftime('%Y-%m-%d %H:%M:%S %z')}
        BODY
      end
    end

    context "when locale and timezone are set to system's default" do
      let(:time_zone) { 'system' }
      let(:locale)    { 'system' }

      it 'creates a note with untranslated content' do
        ticket = create(:ticket, state_name: 'open', priority_name: '3 high')
        job.run(true)

        expect(Ticket::Article.last.body).to eq(<<~BODY)
          Lieber Absender, wir haben Ihre Anfrage erhalten und werden sie so schnell wie möglich bearbeiten.

          Daten:
          * Status: open
          * Priorität: 3 high
          * Erstellt am: #{ticket.created_at.in_time_zone(Setting.get('timezone_default')).strftime('%Y-%m-%d %H:%M:%S %z')}
        BODY
      end
    end
  end
end
