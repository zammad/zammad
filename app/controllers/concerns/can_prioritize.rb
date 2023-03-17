# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module CanPrioritize
  extend ActiveSupport::Concern

  def prio
    klass.without_callback(:update, :before, :rearrangement) do
      params[:prios].each do |entry_prio|
        entry = prio_find(entry_prio) || prio_create(entry_prio)
        next if entry.prio == entry_prio[1]

        entry.prio = entry_prio[1]
        entry.save!
      end
    end
    render json: { success: true }, status: :ok
  end

  def prio_create(entry_prio)
    klass.try(:prio_create, id: entry_prio[0], prio: entry_prio[1], current_user: current_user)
  end

  def prio_find(entry_prio)
    klass.find_by(id: entry_prio[0])
  end
end
