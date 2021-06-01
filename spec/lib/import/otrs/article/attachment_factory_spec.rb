# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/import_factory_examples'

RSpec.describe Import::OTRS::Article::AttachmentFactory do
  let(:start_import) do
    described_class.import(
      attachments:   attachments,
      local_article: local_article
    )
  end

  let(:attachments) do
    [
      load_attachment_json('default'),
      load_attachment_json('default'),
      load_attachment_json('default')
    ]
  end

  let(:local_article) { instance_double(Ticket::Article, ticket_id: 1337, id: 42) }

  def load_attachment_json(file)
    json_fixture("import/otrs/article/attachment/#{file}")
  end

  def import_expectations
    expect(Store).to receive(:add).exactly(3).times.with(hash_including(
                                                           object: 'Ticket::Article',
                                                           o_id:   local_article.id,
                                                         ))
  end

  def article_attachment_expectations(article_attachments)
    allow(local_article).to receive(:attachments).and_return(article_attachments)
  end

  it_behaves_like 'Import factory'

  it 'imports' do
    article_attachment_expectations([])
    import_expectations
    start_import
  end

  it 'deletes old and reimports' do
    dummy_attachment = double()
    expect(dummy_attachment).to receive(:delete)
    article_attachment_expectations([dummy_attachment])
    import_expectations
    start_import
  end

  it 'skips import for same count' do
    article_attachment_expectations([1, 2, 3])
    expect(Store).not_to receive(:add)
    start_import
  end
end
