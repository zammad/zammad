# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module CanPrioritize
  extend ActiveSupport::Concern

  def prio
    klass.without_callback(:update, :before, :rearrangement) do
      params[:prios].each do |entry_prio|
        entry = klass.find(entry_prio[0])
        next if entry.prio == entry_prio[1]

        entry.prio = entry_prio[1]
        entry.save!
      end
    end
    render json: { success: true }, status: :ok
  end
end
