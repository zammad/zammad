# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ActiveRecord::Calculations do # rubocop:disable RSpec/FilePath
  describe '#pluck_as_hash' do
    let(:ticket) { create(:ticket) }

    it 'returns array with the hash' do
      result = Ticket.where(id: ticket.id).pluck_as_hash(:title)
      expect(result).to eq [{ title: ticket.title }]
    end

    it 'works given multiple attributes' do
      result = Ticket.where(id: ticket.id).pluck_as_hash(:title, :id)
      expect(result).to eq [{ title: ticket.title, id: ticket.id }]
    end

    it 'works given array' do
      result = Ticket.where(id: ticket.id).pluck_as_hash(%i[title id])
      expect(result).to eq [{ title: ticket.title, id: ticket.id }]
    end
  end
end
