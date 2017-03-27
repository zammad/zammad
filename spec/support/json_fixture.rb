module ZammadHelper
  def json_fixture(file)
    JSON.parse(File.read("spec/fixtures/#{file}.json"))
  end
end
