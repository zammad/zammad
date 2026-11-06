# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::ObjectLink, :aggregate_failures do
  let(:base) { 'https://support.example.com/#' }

  before do
    Setting.set('http_type', 'https')
    Setting.set('fqdn', 'support.example.com')
  end

  def urls(*rows)
    described_class.urls(rows.map(&:stringify_keys)).values
  end

  it 'links tickets, users and organizations to the current interface\'s pages' do
    expect(urls({ type: 'Ticket', id: 8812 }, { type: 'User', id: 2 }, { type: 'Organization', id: 5 }))
      .to eq(["#{base}ticket/zoom/8812", "#{base}user/profile/2", "#{base}organization/profile/5"])
  end

  it 'links a knowledge base answer in the locale of its text' do
    answer = create(:knowledge_base_answer, :published)
    kb_id  = answer.category.knowledge_base_id

    expect(urls({ type: 'KnowledgeBase::Answer', id: answer.id, locale: 'en-us' })).to eq(["#{base}knowledge_base/#{kb_id}/locale/en-us/answer/#{answer.id}"])
    expect(urls({ type: 'KnowledgeBase::Answer', id: answer.id })).to be_empty
    expect(urls({ type: 'KnowledgeBase::Answer', id: 0, locale: 'en-us' })).to be_empty
  end

  it 'links an overview by its link, as both interfaces open it' do
    overview = Overview.find_by(link: 'my_assigned')

    expect(urls({ type: 'Overview', id: overview.id }, { type: 'Overview', id: 0 })).to eq(["#{base}ticket/view/my_assigned"])
  end

  it 'links a type that a class of its own declares, as an addon would add one' do
    stub_const('Service::AI::Tool::ObjectLink::ExampleRecord', Class.new(described_class) { page 'ExampleRecord', 'example/%{id}' })

    expect(urls({ type: 'ExampleRecord', id: 7 })).to eq(["#{base}example/7"])
  end

  it 'links one object by its type and ID' do
    expect(described_class.url(type: 'Ticket', id: 8812)).to eq("#{base}ticket/zoom/8812")
    expect(described_class.url(type: 'Ticket::Article', id: 1)).to be_nil
  end

  it 'gives each row its own link, also for the same object twice' do
    rows = [{ 'type' => 'Ticket', 'id' => 1 }, { 'type' => 'Ticket', 'id' => 1 }]

    expect(described_class.urls(rows).keys).to contain_exactly(be(rows.first), be(rows.last))
  end

  it 'names an object without its title, as its type knows it' do
    expect(described_class.label({ 'type' => 'Ticket', 'id' => 8812, 'number' => '31042', 'title' => 'Help!' })).to eq('Ticket 31042 (ID 8812)')
    expect(described_class.label({ 'type' => 'KnowledgeBase::Answer', 'id' => 3, 'locale' => 'en-us' })).to eq('Knowledge base answer 3 · en-us')
    expect(described_class.label({ 'type' => 'User', 'id' => 2 }, key: 'customer')).to eq('Customer (user 2)')
    expect(described_class.label({ 'type' => 'User', 'id' => 2 }, key: 'user')).to eq('User 2')
    expect(described_class.label({ 'type' => 'Organization', 'id' => 5, 'name' => 'ACME' })).to eq('Organization 5')
  end

  it 'links nothing that has no page of its own' do
    expect(urls({ type: 'Ticket::Article', id: 1 }, { type: 'email', id: 1 }, { type: nil, id: 1 })).to be_empty
  end
end
