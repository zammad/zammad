# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Output::Message, :aggregate_failures do
  describe '.part' do
    let(:customer) { create(:customer, firstname: 'Anna', lastname: 'Example') }
    let(:article)  { create(:ticket_article, :inbound_email, subject: 'Calendar does not sync', body: 'Since the update.', content_type: 'text/plain', created_by_id: customer.id, from: 'Anna Example <anna@example.com>', to: 'support@example.com') }

    before do
      travel_to Time.zone.parse('2026-10-05 08:12:00 UTC')
      Setting.set('timezone_default', 'Europe/Berlin')
    end

    def attach(filename, **preferences)
      create(:store, object: 'Ticket::Article', o_id: article.id, filename:, preferences:)
    end

    it 'gives the message with its type, subject and files with their IDs in the tag of its marked text' do
      log  = attach('outlook.log')
      shot = attach('screenshot.png', 'Content-Type' => 'image/png')
      message = described_class.part(article, position: 2, text: 'Since the update.', length: 100)

      expect(message.content).to include(
        id: article.id, position: 2, type: 'email', sender: 'Customer', from: 'Anna Example', internal: false,
        subject: 'Calendar does not sync', attachments: [{ id: log.id, filename: 'outlook.log', size: 12 }, { id: shot.id, filename: 'screenshot.png', content_type: 'image/png', size: 12 }],
        truncated: false, text: 'Since the update.',
      )
      expect(message.text).to eq(<<~TEXT.chomp)
        <text source="customer" message="2" type="email" from="Anna Example" from_address="Anna Example &lt;anna@example.com&gt;" to="support@example.com" time="2026-10-05 10:12" visibility="public" subject="Calendar does not sync" attachments="outlook.log (id #{log.id}), screenshot.png (id #{shot.id})">
        │ Since the update.
        </text>
      TEXT
    end

    it 'leaves out the images shown inside the text, as GraphQL lists the files' do
      article.update!(content_type: 'text/html', body: '<p>Since the update.</p><img src="cid:shot@example.com">')
      attach('inline.png', 'Content-Type' => 'image/png', 'Content-ID' => 'shot@example.com')
      attach('outlook.log')

      expect(described_class.part(article, position: 1, text: 'Since the update.', length: 100).content[:attachments]).to match([include(filename: 'outlook.log')])
    end

    it 'leaves out the mail\'s own HTML, which the email parser keeps as a file, as the ticket view does' do
      attach('message.html', 'Mime-Type' => 'text/html', 'original-format' => true, 'content-alternative' => true)
      attach('outlook.log')

      expect(described_class.part(article, position: 1, text: 'Since the update.', length: 100).content[:attachments]).to match([include(filename: 'outlook.log')])
      expect(described_class.attachment_counts(Ticket::Article.where(id: article.id))).to eq(article.id => 1)
    end

    it 'names ten files and counts the others' do
      12.times { |index| attach("file-#{index}.log") }
      message = described_class.part(article, position: 1, text: 'Since the update.', length: 100)

      expect(message.content[:attachments].size).to eq(10)
      expect(message.content[:omitted_attachments]).to eq(2)
      expect(message.text).to match(%r{file-9\.log \(id \d+\) and 2 more">})
    end

    it 'cuts the text and says how much of it is shown' do
      message = described_class.part(article, position: 1, text: "#{'word ' * 400}end", length: 1_500)

      expect(message.content).to include(truncated: true, full_length: 2_003).and not_include(:part)
      expect(message.text).to match(%r{ cut="1,\d{3} of 2,003 characters shown">\n})
    end

    it 'leaves out the subject and the files of an excerpt, which says only how many files there are' do
      attach('outlook.log')
      message = described_class.part(article, position: 1, text: 'Since the update.', length: 100, excerpt: true, attachment_count: 2)

      expect(message.content).to include(attachment_count: 2)
      expect(message.content).not_to include(:subject, :attachments, :from_address, :to, :language)
      expect(message.text).to start_with('<text source="customer" message="1" type="email" from="Anna Example" time="2026-10-05 10:12" visibility="public" files="2">')
    end

    it 'says nothing of files in an excerpt of a message without any' do
      message = described_class.part(article, position: 1, text: 'Since the update.', length: 100, excerpt: true, attachment_count: 0)

      expect(message.content).not_to include(:attachment_count)
      expect(message.text).not_to include('files=')
    end

    it "names an email's sender address, its Reply-To, its recipients and the language detected in it" do
      article.update!(from: '"Shop form" <noreply@shop.example>', reply_to: 'Carla Customer <carla@example.com>', cc: 'Anna Lead <anna.lead@example.com>', detected_language: 'de')
      message = described_class.part(article, position: 1, text: 'Hallo', length: 100)

      expect(message.content).to include(
        from_address: 'Shop form <noreply@shop.example>', reply_to: ['Carla Customer <carla@example.com>'],
        to: ['support@example.com'], cc: ['Anna Lead <anna.lead@example.com>'], language: 'German (de)',
      )
      expect(message.text).to include(
        'from_address="Shop form &lt;noreply@shop.example&gt;" reply_to="Carla Customer &lt;carla@example.com&gt;" ' \
        'to="support@example.com" cc="Anna Lead &lt;anna.lead@example.com&gt;" language="German (de)"'
      )
    end

    it 'names ten addresses of a list and counts the others' do
      article.update!(cc: Array.new(12) { |index| "copy#{index}@example.com" }.join(', '))
      message = described_class.part(article, position: 1, text: 'Hi', length: 100)

      expect(message.content[:cc].size).to eq(10)
      expect(message.content[:omitted_addresses]).to eq(cc: 2)
      expect(message.text).to include('copy9@example.com and 2 more"')
    end

    it 'keeps a header that is no valid address list as it was written' do
      article.update!(cc: 'Anna Lead <anna.lead@example.com, broken')

      expect(described_class.part(article, position: 1, text: 'Hi', length: 100).content[:cc]).to eq(['Anna Lead <anna.lead@example.com', 'broken'])
    end

    it 'names no addresses for a message that is no email, and no language where none was detected' do
      note = create(:ticket_article, :internal_note, from: 'Anna Example', to: 'Support', body: 'Called back.', content_type: 'text/plain')
      message = described_class.part(note, position: 1, text: 'Called back.', length: 100)

      expect(message.content).not_to include(:from_address, :reply_to, :to, :cc, :language)
      expect(message.text).not_to include('from_address=', ' to=', 'language=')
    end

    it 'names no writer for a message of the system' do
      article.update!(sender: Ticket::Article::Sender.find_by(name: 'System'))

      expect(described_class.part(article, position: 1, text: 'Escalated.', length: 100).text).to start_with('<text source="system" message="1" type="email" from_address=')
    end
  end

  describe '.attachment_counts' do
    let(:ticket) { create(:ticket) }

    it 'counts the files of each message with one, without the images shown inside its text' do
      with_files = create(:ticket_article, ticket:)
      embedding  = create(:ticket_article, ticket:, content_type: 'text/html', body: '<p>See.</p><img src="cid:shot@example.com">')
      create(:ticket_article, ticket:)
      2.times { |index| create(:store, object: 'Ticket::Article', o_id: with_files.id, filename: "file-#{index}.log") }
      create(:store, object: 'Ticket::Article', o_id: embedding.id, filename: 'shot.png', preferences: { 'Content-ID' => 'shot@example.com' })
      create(:store, object: 'Ticket::Article', o_id: embedding.id, filename: 'sync.log')

      expect(described_class.attachment_counts(ticket.articles)).to eq(with_files.id => 2, embedding.id => 1)
    end

    it 'counts no message whose only file is the mail\'s own HTML' do
      html_mail = create(:ticket_article, ticket:)
      create(:store, object: 'Ticket::Article', o_id: html_mail.id, filename: 'message.html', preferences: { 'original-format' => true })

      expect(described_class.attachment_counts(ticket.articles)).to eq({})
    end
  end
end
