require 'rails_helper'

RSpec.describe SearchIndexJob, type: :job do

  it 'calls search_index_update_backend on matching record' do
    user = create(:user)
    expect(::User).to receive(:lookup).with(id: user.id).and_return(user)
    expect(user).to receive(:search_index_update_backend)

    described_class.perform_now('User', user.id)
  end

  it "doesn't perform for non existing records" do
    id = 9999
    expect(::User).to receive(:lookup).with(id: id).and_return(nil)
    described_class.perform_now('User', id)
  end

  it 'retries on exception' do
    expect(::User).to receive(:lookup).and_raise(RuntimeError)
    described_class.perform_now('User', 1)
    expect(described_class).to have_been_enqueued
  end
end
