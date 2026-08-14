# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'HasTaskbars' do
  subject { create(described_class.name.underscore) }

  describe '#destroy_taskbars' do
    it 'destroys related taskbars' do
      taskbar = create(:taskbar, key: Taskbar.entity_key(subject))
      subject.destroy
      expect { taskbar.reload }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end
end
