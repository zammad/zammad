# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'AsBatches' do
  def priorities_asc(size)
    result = []
    Ticket::Priority.order(name: :asc).as_batches(size: size) do |prio|
      result << prio
    end
    result
  end

  def priorities_desc(size)
    result = []
    Ticket::Priority.order(name: :desc).as_batches(size: size) do |prio|
      result << prio
    end
    result
  end

  context 'when batch is smaller then total result' do
    it 'does return all priorities ascending' do
      expect(priorities_asc(1)).to eq([ Ticket::Priority.find_by(name: '1 low'), Ticket::Priority.find_by(name: '2 normal'), Ticket::Priority.find_by(name: '3 high') ])
    end

    it 'does return all priorities decending' do
      expect(priorities_desc(1)).to eq([ Ticket::Priority.find_by(name: '3 high'), Ticket::Priority.find_by(name: '2 normal'), Ticket::Priority.find_by(name: '1 low') ])
    end
  end

  context 'when batch is equal to total result' do
    it 'does return all priorities ascending' do
      expect(priorities_asc(100)).to eq([ Ticket::Priority.find_by(name: '1 low'), Ticket::Priority.find_by(name: '2 normal'), Ticket::Priority.find_by(name: '3 high') ])
    end

    it 'does return all priorities decending' do
      expect(priorities_desc(100)).to eq([ Ticket::Priority.find_by(name: '3 high'), Ticket::Priority.find_by(name: '2 normal'), Ticket::Priority.find_by(name: '1 low') ])
    end
  end
end
