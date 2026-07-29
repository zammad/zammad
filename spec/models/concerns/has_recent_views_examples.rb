# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'HasRecentViews' do
  subject { create(described_class.name.underscore) }

  describe '#recent_view_destroy' do
    it 'destroys recent views' do
      recent_view = create(:recent_view, o: subject)
      subject.destroy
      expect { recent_view.reload }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end
end
