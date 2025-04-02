# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Taskbar::Init
  include ::Mixin::HasBackends

  def self.run(current_user)
    object_ids = current_user.taskbars.to_object_ids

    backends.each_with_object({ assets: {} }) do |elem, memo|
      elem.new(current_user:, object_ids:).data(memo)
    end
  end
end
