# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'HasRecentCloses' do
  subject { create(described_class.name.underscore) }

  describe '#destroy_recent_closes' do
    it 'destroys recent closes' do
      recent_close = create(:recent_close, recently_closed_object: subject)
      subject.destroy
      expect { recent_close.reload }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end
end
