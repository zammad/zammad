# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::EmailBuild, type: :model do
  describe '#build' do
    let(:html_body) do
      <<~MSG_HTML.chomp
        <!DOCTYPE html>
        <html>
          <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
          </head>
          <body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;">
            <div>&gt; Welcome!</div><div>&gt;</div><div>&gt; Thank you for installing Zammad. äöüß</div><div>&gt;</div>
          </body>
        </html>
      MSG_HTML
    end

    let(:plain_text_body) do
      <<~MSG_TEXT.chomp
        > Welcome!
        >
        > Thank you for installing Zammad. äöüß
        >
      MSG_TEXT
    end
    let(:parser)      { Channel::EmailParser.new }
    let(:parsed_data) { parser.parse(mail.to_s) }

    let(:html_part_attachment) do
      parsed_data[:attachments]
        .find { |attachment| attachment[:filename] == 'message.html' }
    end

    let(:file_attachment) do
      parsed_data[:attachments]
        .find { |attachment| attachment[:filename] == filename }
    end

    shared_examples 'adding the email html part as an attachment' do
      it 'adds the html part as an attachment' do
        expect(html_part_attachment).to be_a Hash
      end

      it 'adds the html part as an attachment' do
        expect(html_part_attachment).to include(
          'filename'    => 'message.html',
          'preferences' => include('content-alternative' => true, 'Charset' => 'UTF-8',
                                   'Mime-Type' => 'text/html', 'original-format' => true)
        )
      end

      it 'does not include content-id property in attachment preferences' do
        expect(html_part_attachment).not_to include(
          'preferences' => include('Content-ID')
        )
      end
    end

    shared_examples 'adding a text file as an attachment' do
      it 'adds the text file as an attachment' do
        expect(file_attachment).to include(
          'filename'    => filename,
          'preferences' => include('Charset' => 'UTF-8', 'Mime-Type' => mime_type,
                                   'Content-Type' => "text/plain; charset=UTF-8; filename=#{filename}")
        )
      end

      it 'does not include content* properties in attachment preferences' do
        expect(file_attachment).not_to include(
          'preferences' => include('Content-ID', 'content-alternative')
        )
      end
    end

    shared_examples 'adding a file as an attachment' do |file_type|
      it "adds a #{file_type} as an attachment'" do
        expect(file_attachment).to include(
          'data'        => content, 'filename' => filename,
          'preferences' => include('Charset' => 'UTF-8', 'Mime-Type' => mime_type,
                                   'Content-Type' => preferences_content_type)
        )
      end

      it 'does not include content* properties in attachment preferences' do
        expect(file_attachment).not_to include(
          'preferences' => include('content-alternative')
        )
      end
    end

    shared_examples 'not adding email content as attachment' do
      it 'does not add email content as an attachment' do
        expect(html_part_attachment).to be_nil
      end
    end

    context 'with email only' do
      let(:mail) do
        described_class.build(
          from:         'sender@example.com',
          to:           'recipient@example.com',
          body:         mail_body,
          content_type: content_type
        )
      end

      let(:expected_text) do
        <<~MSG_TEXT.chomp
          > Welcome!\r
          >\r
          > Thank you for installing Zammad. äöüß\r
          >\r
        MSG_TEXT
      end

      context 'when email contains only html' do
        let(:mail_body) { html_body }
        let(:content_type) { 'text/html' }

        let(:expected_html) do
          <<~MSG_HTML.chomp
            <!DOCTYPE html>\r
            <html>\r
              <head>\r
                <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>\r
              </head>\r
              <body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;">\r
                <div>&gt; Welcome!</div><div>&gt;</div><div>&gt; Thank you for installing Zammad. äöüß</div><div>&gt;</div>\r
              </body>\r
            </html>
          MSG_HTML
        end

        let(:expected_body) { '<div>&gt; Welcome!</div><div>&gt;</div><div>&gt; Thank you for installing Zammad. äöüß</div><div>&gt;</div>' }

        it 'builds a mail with a text part' do
          expect(mail.text_part.body.to_s).to eq expected_text
        end

        it 'builds a mail with a html part' do
          expect(mail.html_part.body.to_s).to eq expected_html
        end

        it 'builds a mail that is parsed correctly' do
          expect(parsed_data).to include(body: expected_body, content_type: 'text/html')
        end

        it_behaves_like 'adding the email html part as an attachment'
      end

      context 'when email contains only plain text' do
        let(:mail_body)    { plain_text_body }
        let(:content_type) { 'text/plain' }

        it 'builds a mail with a text part' do
          expect(mail.body.to_s).to eq expected_text
        end

        it 'does not build a html part' do
          expect(mail.html_part).to be_nil
        end

        it 'builds a mail that is parsed correctly' do
          expect(parsed_data).to  include(body: plain_text_body, content_type: 'text/plain')
        end

        it 'does not have an attachment' do
          expect(parsed_data[:attachments].first).to be_nil
        end

        it_behaves_like 'not adding email content as attachment'
      end
    end

    context 'with email and attachment' do
      let(:mail) do
        described_class.build(
          from:         'sender@example.com',
          to:           'recipient@example.com',
          body:         mail_body,
          content_type: content_type,
          attachments:  attachments
        )
      end

      let(:filename)  { 'somename.txt' }
      let(:mime_type) { 'text/plain' }
      let(:content)   { 'Some text' }

      let(:direct_attachment) do
        [{
          'Mime-Type' => mime_type,
          :content    => content,
          :filename   => filename
        }]
      end
      let(:ticket) { create(:ticket, title: 'some article text attachment test', group: group) }
      let(:group)  { Group.lookup(name: 'Users') }

      let(:article) do
        create(:ticket_article,
               ticket: ticket,
               body:   'some message article helper test1 <div><img style="width: 85.5px; height: 49.5px" src="cid:15.274327094.140938@zammad.example.com">asdasd<img src="cid:15.274327094.140939@zammad.example.com"><br>')
      end

      let(:store_attributes) do
        {
          object:      'Ticket::Article',
          o_id:        article.id,
          data:        content,
          filename:    filename,
          preferences: {
            'Mime-Type' => mime_type
          }
        }
      end

      let(:store) { create(:store, **store_attributes) }

      shared_context 'with attachment checks' do
        context 'when attachment is a text file' do

          it_behaves_like 'adding a text file as an attachment'
        end

        context 'when attachment is a image file' do
          let(:filename)                 { 'somename.png' }
          let(:mime_type)                { 'image/png' }
          let(:preferences_content_type) { "#{mime_type}; filename=#{filename}" }
          let(:content)                  { 'xxxxxxx' }

          it_behaves_like 'adding a file as an attachment', 'image'
        end

        context 'when attachment is a calendar file' do
          let(:filename)  { 'schedule.ics' }
          let(:mime_type)                { 'text/calendar' }
          let(:preferences_content_type) { "#{mime_type}; charset=UTF-8; filename=#{filename}" }
          let(:content)                  { 'xxxxxxx' }

          it_behaves_like 'adding a file as an attachment', 'calendar'
        end

      end

      context 'with html email' do
        let(:mail_body)    { html_body }
        let(:content_type) { 'text/html' }

        context 'with direct attachment' do
          let(:attachments) { direct_attachment }

          it 'has two attachments' do
            expect(parsed_data[:attachments].size).to eq 2
          end

          it_behaves_like 'adding the email html part as an attachment'

          include_context 'with attachment checks'
        end

        context 'with attachement from store' do
          let(:attachments) { [ store  ] }
          let(:filename)    { 'text_file.txt' }
          let(:mime_type)   { 'text/plain' }

          it 'has two attachments' do
            expect(parsed_data[:attachments].size).to eq 2
          end

          it_behaves_like 'adding the email html part as an attachment'

          include_context 'with attachment checks'
        end
      end

      context 'with plain text email' do
        let(:mail_body)    { plain_text_body }
        let(:content_type) { 'text/plain' }

        context 'with direct attachment' do
          let(:attachments) { direct_attachment }
          let(:filename)  { 'somename.txt' }
          let(:mime_type) { 'text/plain' }

          it 'has only one attachment' do
            expect(parsed_data[:attachments].size).to eq 1
          end

          it_behaves_like 'not adding email content as attachment'

          include_context 'with attachment checks'
        end

        context 'with attachement from store' do
          let(:attachments) { [ store  ] }
          let(:filename)  { 'text_file.txt' }
          let(:mime_type) { 'text/plain' }
          let(:mail_body) do
            <<~MSG_TEXT.chomp
              > Welcome!
              >
              > Email Content
            MSG_TEXT
          end
          let(:content) { 'Text Content' }

          it 'has only one attachment' do
            expect(parsed_data[:attachments].size).to eq 1
          end

          # #2362 - Attached text files get prepended on e-mail reply instead of appended
          it 'Email Content should appear before the Text Content within the raw email' do
            expect(mail.to_s).to match(%r{Email Content[\s\S]*Text Content})
          end

          it_behaves_like 'not adding email content as attachment'

          include_context 'with attachment checks'
        end
      end
    end
  end

  describe '#recipient_line' do
    let(:email)                    { 'some.body@example.com' }
    let(:generated_recipient_line) { described_class.recipient_line(realname, email) }

    context 'with quote in the realname' do
      let(:realname) { 'Somebody @ "Company"' }

      it 'escapes the quotes' do
        expected_recipient_line = '"Somebody @ \"Company\"" <some.body@example.com>'
        expect(generated_recipient_line).to eq expected_recipient_line
      end
    end

    context 'with a simple realname with no special characters' do
      let(:realname) { 'Somebody' }

      it 'wraps the realname with quotes and wraps the email with <>' do
        expected_recipient_line = 'Somebody <some.body@example.com>'
        expect(generated_recipient_line).to eq expected_recipient_line
      end
    end

    context 'with special characters (|) in the realname' do
      let(:realname) { 'Somebody | Some Org' }

      it 'wraps the realname with quotes and wraps the email with <>' do
        expected_recipient_line = '"Somebody | Some Org" <some.body@example.com>'
        expect(generated_recipient_line).to eq expected_recipient_line
      end
    end

    context 'with special characters (spaces) in the realname' do
      let(:realname) { 'Test Admin Agent via Support' }

      it 'wraps the realname with quotes and wraps the email with <>' do
        expected_recipient_line = '"Test Admin Agent via Support" <some.body@example.com>'
        expect(generated_recipient_line).to eq expected_recipient_line
      end
    end
  end

  # https://github.com/zammad/zammad/issues/165
  describe '#html_mail_client_fixes' do
    let(:generated_html) { described_class.html_mail_client_fixes(html) }

    shared_examples 'adding styles to the element' do
      it 'adds style to the element' do
        expect(generated_html).to eq expected_html
      end

      it { expect(generated_html).not_to eq html }
    end

    context 'when html element is a blockquote' do
      let(:html) do
        <<~HTML.chomp
          <blockquote type="cite">some
          text
          </blockquote>
          123
          <blockquote type="cite">some
          text
          </blockquote>
        HTML
      end
      let(:expected_html) do
        <<~HTML.chomp
          <blockquote type="cite" style="border-left: 2px solid blue; margin: 0 0 16px; padding: 8px 12px 8px 12px;">some
          text
          </blockquote>
          123
          <blockquote type="cite" style="border-left: 2px solid blue; margin: 0 0 16px; padding: 8px 12px 8px 12px;">some
          text
          </blockquote>
        HTML
      end

      it_behaves_like 'adding styles to the element'
    end

    context 'when html element is a p' do
      let(:html) do
        <<~HTML.chomp
          <p>some
          text
          </p>
          <p>123</p>
        HTML
      end
      let(:expected_html) do
        <<~HTML.chomp
          <p style="margin: 0;">some
          text
          </p>
          <p style="margin: 0;">123</p>
        HTML
      end

      it_behaves_like 'adding styles to the element'
    end

    context 'when html element is a hr' do
      let(:html) do
        <<~HTML.chomp
          <p>sometext</p><hr><p>123</p>
        HTML
      end
      let(:expected_html) do
        <<~HTML.chomp
          <p style="margin: 0;">sometext</p><hr style="margin-top: 6px; margin-bottom: 6px; border: 0; border-top: 1px solid #dfdfdf;"><p style="margin: 0;">123</p>
        HTML
      end

      it_behaves_like 'adding styles to the element'

      context 'when hr is a closing tag' do
        let(:html) do
          <<~HTML.chomp
            <p>sometext</p></hr>
          HTML
        end
        let(:expected_html) do
          <<~HTML.chomp
            <p style="margin: 0;">sometext</p><hr style="margin-top: 6px; margin-bottom: 6px; border: 0; border-top: 1px solid #dfdfdf;">
          HTML
        end

        it_behaves_like 'adding styles to the element'
      end
    end

    context 'when html element does not contian p, hr or blockquote' do
      let(:html) do
        <<~HTML.chomp
          <div>
            <h2>Testing</h2>
            <ul>
              <li><a href="#"><b>Test</b> <span>1</span></a></li>
              <li><a href="#"><b>Test</b> <span>2</span></a></li>
              <li><a href="#"><b>Test</b> <span>3</span></a></li>
            </ul>
          </div>
        HTML
      end

      it 'does not add style to the element' do
        expect(generated_html).to eq html
      end
    end
  end

  describe '#html_complete_check' do
    let(:generated_html) { described_class.html_complete_check(html) }

    context 'when html element includes an html tag' do
      let(:html) { '<!DOCTYPE html><html><b>test</b></html>' }

      it 'returns the html as it is' do
        expect(generated_html).to eq html
      end
    end

    context 'when html does not include an html tag' do
      let(:html) { '<b>test</b>' }

      it 'adds DOCTYPE tag to the element' do
        expect(generated_html).to start_with '<!DOCTYPE'
      end

      it 'adds an html tag' do
        expect(generated_html).to match '<html>'
      end

      it 'adds the original element' do
        expect(generated_html).to match html
      end
    end

    # Issue #1230, missing backslashes
    # 'Test URL: \\storage\project\100242-Inc'
    context 'when html includes a backslash' do
      let(:html) { '<b>Test URL</b>: \\\\storage\\project\\100242-Inc' }

      it 'keeps the backslashes' do
        expect(generated_html).to include html
      end
    end

    context 'with a configured html_email_css_font setting' do
      let(:html)     { '<b>test</b>' }
      let(:css_font) { "font-family:'Helvetica Neue', sans-serif; font-size: 12px;" }

      before { Setting.set('html_email_css_font', css_font) }

      it 'includes the configured css font' do
        expect(generated_html).to match css_font
      end
    end
  end
end
