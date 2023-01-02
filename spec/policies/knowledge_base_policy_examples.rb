# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_context 'with KB policy check' do |editor:, reader:, none:, method:, access_method: :access|
  let(:access_method) { access_method }

  it 'returns true if editor' do
    mock_permission 'editor'

    expect(policy.send(method)).to be editor
  end

  it 'returns true if reader' do
    mock_permission 'reader'

    expect(policy.send(method)).to be reader
  end

  it 'returns false if none' do
    mock_permission 'none'

    expect(policy.send(method)).to be none
  end

  def mock_permission(access)
    allow(policy)
      .to receive(access_method)
      .and_return(access)
  end
end
