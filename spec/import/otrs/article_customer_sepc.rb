require 'rails_helper'

RSpec.describe Import::OTRS::ArticleCustomer do

  def load_article_json(file)
    json_fixture("import/otrs/article/#{file}")
  end

  let(:instance_id) { 1337 }
  let(:existing_object) { instance_double(import_object) }
  let(:import_object) { User }
  let(:object_structure) { load_article_json('customer_phone') }
  let(:start_import_test) { described_class.new(object_structure) }

  it 'finds customers by email' do
    expect(import_object).to receive(:find_by).with(email: 'kunde2@kunde.de').and_return(existing_object)
    expect(existing_object).to receive(:id).and_return(instance_id)
    expect(import_object).not_to receive(:create)
    start_import_test
    expect(object_structure['created_by_id']).to eq(instance_id)
  end

  it 'finds customers by login' do
    expect(import_object).to receive(:find_by).with(email: 'kunde2@kunde.de')
    expect(import_object).to receive(:find_by).with(login: 'kunde2@kunde.de').and_return(existing_object)
    expect(existing_object).to receive(:id).and_return(instance_id)
    expect(import_object).not_to receive(:create)
    start_import_test
    expect(object_structure['created_by_id']).to eq(instance_id)
  end

  it 'creates customers' do
    expect(import_object).to receive(:find_by).at_least(:once)
    expect(import_object).to receive(:create).and_return(existing_object)
    expect(existing_object).to receive(:id).and_return(instance_id)
    start_import_test
    expect(object_structure['created_by_id']).to eq(instance_id)
  end
end
