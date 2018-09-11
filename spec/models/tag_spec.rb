require 'rails_helper'

RSpec.describe Tag do

  context 'rename' do
    before(:each) do
      Tag::Item.lookup_by_name_and_create('test1')
    end

    def tag_rename
      Tag::Item.rename(
        id: Tag::Item.lookup(name: 'test1').id,
        name: 'test1_renamed',
        updated_by_id: 1,
      )
    end

    it 'overview conditions with a single tag' do
      object = create :overview, condition: { 'ticket.tags' => { operator: 'contains one', value: 'test1' } }
      tag_rename
      expect(Overview.find(object.id).condition['ticket.tags'][:value]).to eq('test1_renamed')
    end

    it 'overview conditions with a tag list ' do
      object = create :overview, condition: { 'ticket.tags' => { operator: 'contains all', value: 'test1, test2, test3' } }
      tag_rename
      expect(Overview.find(object.id).condition['ticket.tags'][:value]).to eq('test1_renamed, test2, test3')
    end

    it 'trigger conditions with a single tag' do
      object = create :trigger, condition: { 'ticket.tags' => { operator: 'contains one', value: 'test1' } }
      tag_rename
      expect(Trigger.find(object.id).condition['ticket.tags'][:value]).to eq('test1_renamed')
    end

    it 'trigger conditions with a tag list ' do
      object = create :trigger, condition: { 'ticket.tags' => { operator: 'contains all', value: 'test1, test2, test3' } }
      tag_rename
      expect(Trigger.find(object.id).condition['ticket.tags'][:value]).to eq('test1_renamed, test2, test3')
    end

    it 'trigger performs with a single tag' do
      object = create :trigger, perform: { 'ticket.tags' => { operator: 'contains one', value: 'test1' } }
      tag_rename
      expect(Trigger.find(object.id).perform['ticket.tags'][:value]).to eq('test1_renamed')
    end

    it 'trigger performs with a tag list ' do
      object = create :trigger, perform: { 'ticket.tags' => { operator: 'contains all', value: 'test1, test2, test3' } }
      tag_rename
      expect(Trigger.find(object.id).perform['ticket.tags'][:value]).to eq('test1_renamed, test2, test3')
    end

    it 'scheduler conditions with a single tag' do
      object = create :job, condition: { 'ticket.tags' => { operator: 'contains one', value: 'test1' } }
      tag_rename
      expect(Job.find(object.id).condition['ticket.tags'][:value]).to eq('test1_renamed')
    end

    it 'scheduler conditions with a tag list ' do
      object = create :job, condition: { 'ticket.tags' => { operator: 'contains all', value: 'test1, test2, test3' } }
      tag_rename
      expect(Job.find(object.id).condition['ticket.tags'][:value]).to eq('test1_renamed, test2, test3')
    end

    it 'scheduler performs with a single tag' do
      object = create :job, perform: { 'ticket.tags' => { operator: 'contains one', value: 'test1' } }
      tag_rename
      expect(Job.find(object.id).perform['ticket.tags'][:value]).to eq('test1_renamed')
    end

    it 'scheduler performs with a tag list ' do
      object = create :job, perform: { 'ticket.tags' => { operator: 'contains all', value: 'test1, test2, test3' } }
      tag_rename
      expect(Job.find(object.id).perform['ticket.tags'][:value]).to eq('test1_renamed, test2, test3')
    end

    it 'PostmasterFilter performs with a single tag' do
      object = create :postmaster_filter, perform: { 'x-zammad-ticket-tags' => { operator: 'contains one', value: 'test1' } }
      tag_rename
      expect(PostmasterFilter.find(object.id).perform['x-zammad-ticket-tags'][:value]).to eq('test1_renamed')
    end

    it 'PostmasterFilter performs with a tag list ' do
      object = create :postmaster_filter, perform: { 'x-zammad-ticket-tags' => { operator: 'contains all', value: 'test1, test2, test3' } }
      tag_rename
      expect(PostmasterFilter.find(object.id).perform['x-zammad-ticket-tags'][:value]).to eq('test1_renamed, test2, test3')
    end
  end
end
