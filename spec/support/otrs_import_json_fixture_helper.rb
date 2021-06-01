# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ZammadHelper
  def json_fixture(file)
    JSON.parse(File.read("spec/fixtures/#{file}.json"))
  end
end
