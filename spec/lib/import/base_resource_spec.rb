require 'rails_helper'

RSpec.describe Import::BaseResource do

  it "needs an implementation of the 'import_class' method" do
    expect {
      described_class.new(attributes_for(:group))
    }.to raise_error(RuntimeError)
  end
end
