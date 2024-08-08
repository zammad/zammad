# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe '.eco files check', :aggregate_failures do
  eco_files = Rails.root.glob('**/*.eco')

  it 'only runs the test as long as .eco files are present - delete the test once they are gone' do
    expect(eco_files.count).to be_positive
  end

  it 'avoids double HTML encoding' do
    eco_files.each do |file| # rubocop:disable RSpec/IteratedExpectation
      expect(file).to avoid_double_encoding_t.and(avoid_double_encoding_p)
    end
  end

  matcher :avoid_double_encoding_t do
    match { !actual.read.match(%r{<%=\s*@T}) }
    failure_message { "#{actual.relative_path_from(Rails.root)} performs incorrect double HTML encoding via '<%= @T()', please change it to '<%- @T'" }
  end

  matcher :avoid_double_encoding_p do
    match { !actual.read.match(%r{<%=\s*@P}) }
    failure_message { "#{actual.relative_path_from(Rails.root)} performs incorrect double HTML encoding via '<%= @P()', please change it to '<%- @P'" }
  end
end
