# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Subject do
  let(:ticket) { create(:ticket) }

  describe '.subject_build' do
    it 'build subject based on new title' do
      expect(ticket.subject_build('other title')).to eq("other title [Ticket##{ticket.number}]")
    end

    it 'build subject based on new title with ticket_hook_position left' do
      Setting.set('ticket_hook_position', 'left')
      expect(ticket.subject_build('other title')).to eq("[Ticket##{ticket.number}] other title")
    end

    it 'build subject based on new title without ticket_hook_position' do
      Setting.set('ticket_hook_position', '')
      expect(ticket.subject_build('other title')).to eq('other title')
    end

    it 'build subject based with forward argument' do
      expect(ticket.subject_build('other title', 'forward')).to eq("FWD: other title [Ticket##{ticket.number}]")
    end

    it 'build subject based with reply argument' do
      expect(ticket.subject_build('other title', 'reply')).to eq("RE: other title [Ticket##{ticket.number}]")
    end
  end

  describe '.subject_clean' do
    it 'cleanup subject with undefined string' do
      expect(ticket.subject_clean(nil)).to eq('')
    end

    it 'cleanup subject with empty string' do
      expect(ticket.subject_clean('')).to eq('')
    end

    it 'cleanup subject with long string which need to be truncated by [...]' do
      expect(ticket.subject_clean('123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890')).to eq('12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890[...]')
    end

    it 'cleanup subject with regular ticket#' do
      expect(ticket.subject_clean("something [Ticket##{ticket.number}]")).to eq('something')
    end

    it 'cleanup subject with regular ticket# multiple time' do
      expect(ticket.subject_clean("[Ticket##{ticket.number}] [Ticket##{ticket.number}] something [Ticket##{ticket.number}]")).to eq('something')
    end

    it 'cleanup subject with foreign ticket#' do
      expect(ticket.subject_clean('something [Ticket#123456]')).to eq('something [Ticket#123456]')
    end

    it 'cleanup subject with some reply signs' do
      expect(ticket.subject_clean('RE: RE: Re[5]: something [Ticket#123456]')).to eq('something [Ticket#123456]')
    end
  end

end
