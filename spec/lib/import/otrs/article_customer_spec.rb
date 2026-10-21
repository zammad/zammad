# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Import::OTRS::ArticleCustomer do

  def load_article_json(file)
    json_fixture("import/otrs/article/#{file}")
  end

  let(:instance_id)       { 1337 }
  let(:existing_object)   { instance_double(import_object) }
  let(:import_object)     { User }
  let(:object_structure)  { load_article_json('customer_phone') }
  let(:start_import_test) { described_class.new(object_structure) }

  it 'finds customers by email' do
    allow(import_object).to receive(:find_by).with(email: 'kunde2@kunde.de').and_return(existing_object)

    expect(import_object).not_to receive(:create)
    start_import_test
  end

  it 'finds customers by login' do
    allow(import_object).to receive(:find_by)
    allow(import_object).to receive(:by_login).with('kunde2@kunde.de').and_return(instance_double(ActiveRecord::Relation, take: existing_object))

    expect(import_object).not_to receive(:create)
    start_import_test
  end

  it 'creates customers', :aggregate_failures do
    allow(import_object).to receive_messages(find_by: nil, create: existing_object)

    start_import_test

    expect(import_object).to have_received(:find_by).at_least(:once)
    expect(import_object).to have_received(:create).with(hash_including(login: 'kunde2@kunde.de', email: 'kunde2@kunde.de'))
  end

  it 'creates customers with special encoding in name' do
    expect { described_class.new(load_article_json('customer_special_chars')) }.to change(User, :count).by(1)
    expect(User.last.login).to eq('user.hernandez@example.com')
  end

  it 'creates customers with special from email syntax' do
    expect { described_class.new(load_article_json('from_bracket_email_syntax')) }.to change(User, :count).by(1)
    expect(User.last.login).to eq('user@example.com')
  end

  it 'converts emails to downcase' do
    Setting.set('import_mode', true)
    expect { described_class.new(load_article_json('from_capital_case')) }.to change(User, :count).by(1)
    expect(User.last.email).to eq('user@example.com')
    expect(User.last.login).to eq('user@example.com')
  end

  describe '.find' do

    it 'returns nil if no email could be found' do
      expect(described_class.find({})).to be_nil
    end
  end

  describe '.local_email' do

    it 'returns nil if no email could be found' do
      expect(described_class.local_email(nil)).to be_nil
    end

    it 'returns the parameter if no email could be found' do
      not_an_email = 'thisisnotanemail'
      expect(described_class.local_email(not_an_email)).to eq(not_an_email)
    end
  end
end
