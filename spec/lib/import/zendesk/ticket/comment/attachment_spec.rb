require 'rails_helper'

RSpec.describe Import::Zendesk::Ticket::Comment::Attachment do

  it 'downloads and stores attachments' do

    local_article = double(id: 1337)

    attachment = double(
      file_name:    'Example.zip',
      content_type: 'application/zip',
      content_url:  'https://dl.remote.tld/394r0eifwskfjwlw3slf'
    )

    response = double(
      body:    'content',
      success?: true,
    )

    expect(UserAgent).to receive(:get).with(attachment.content_url, any_args).and_return(response)

    add_args = {
      object:      'Ticket::Article',
      o_id:        local_article.id,
      data:        response.body,
      filename:    attachment.file_name,
      preferences: {
        'Content-Type' => attachment.content_type
      },
      created_by_id: 1
    }

    expect(Store).to receive(:add).with(add_args)

    described_class.new(attachment, local_article)
  end
end
