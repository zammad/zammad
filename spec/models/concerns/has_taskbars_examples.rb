# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'HasTaskbars' do
  subject { create(described_class.name.underscore) }

  describe '#destroy_taskbars' do
    it 'destroys related taskbars' do
      taskbar = create(:taskbar, key: Taskbar.entity_key(subject))
      subject.destroy
      expect { taskbar.reload }.to raise_exception(ActiveRecord::RecordNotFound)
    end

    # A tab of a part of the record is still a tab of the record (see Taskbar.entity_key).
    it 'destroys related taskbars with a qualified key' do
      taskbar = create(:taskbar, key: Taskbar.entity_key(subject, 'de-de'))
      subject.destroy
      expect { taskbar.reload }.to raise_exception(ActiveRecord::RecordNotFound)
    end

    it 'keeps the taskbars of another record with the same key prefix' do
      taskbar = create(:taskbar, key: Taskbar.entity_key(subject).sub(%r{\d+$}, "#{subject.id}00"))
      subject.destroy
      expect { taskbar.reload }.not_to raise_exception
    end
  end
end
