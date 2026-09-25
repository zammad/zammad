# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ExcelSheet::AI::Analytics::WithUsage do
  subject(:excel_sheet) { described_class.new(entries: [entry], timezone: 'Europe/Berlin', locale: Locale.first) }

  let(:entry) do
    {
      content:  {},
      payload:  {},
      context:  {},
      ratings:  [
        { user_id: 1, user_login: 'agent1', rating: true },
        { user_id: 2, user_login: 'agent2', rating: false },
      ],
      comments: [],
    }
  end

  describe '#gen_rows' do
    before { allow(excel_sheet).to receive(:gen_row_by_header) }

    it 'lists every rating with the agent who gave it' do
      excel_sheet.gen_rows

      expect(excel_sheet).to have_received(:gen_row_by_header)
        .with(include(ratings: "agent1 (#1): like\nagent2 (#2): dislike"))
    end
  end
end
