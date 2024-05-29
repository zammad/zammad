# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailBuild > Inline Images Adjustments', aggregate_failures: true, type: :model do
  let(:html_body) do
    <<~HTML.chomp
      <!DOCTYPE html>
      <html>
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        </head>
        <body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;">
          <img style="width: 125px; max-width: 100%; height: 187.5px;" src="cid:1.e83460e9-7e36-48f7-97db-dc7f0ba7c51f@zammad.example.com">
          <br><br>
          <div data-signature="true" data-signature-id="1">
          Test Admin Agent<br><br>
          --<br>
          Super Support - Waterford Business Park<br>
          5201 Blue Lagoon Drive - 8th Floor &amp; 9th Floor - Miami, 33126 USA<br>
          Email: hot@example.com - Web: <a href="http://www.example.com/" rel="nofollow noreferrer noopener" target="_blank">http://www.example.com/</a><br>
          --
          </div>
        </body>
      </html>
    HTML
  end

  let(:mail) do
    Channel::EmailBuild.build(
      from:         'sender@example.com',
      to:           'recipient@example.com',
      body:         html_body,
      content_type: 'text/html',
    )
  end

  context 'when an email is built with inline images' do
    it 'adjusts the inline images width and height' do
      expect(mail.html_part.body.to_s).to include('<img style="width: 125px; max-width: 100%; height: 187.5px;" src="cid:1.e83460e9-7e36-48f7-97db-dc7f0ba7c51f@zammad.example.com" height="187.5" width="125">')
    end
  end
end
