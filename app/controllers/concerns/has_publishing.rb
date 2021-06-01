# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasPublishing
  extend ActiveSupport::Concern

  included do
    CanBePublished::StateMachine.aasm.events.each do |event|
      define_method "has_publishing_#{event.name}" do
        object = klass.find params[:id]
        object.can_be_published_aasm.aasm.fire! event.name, current_user

        render json: klass.full(params[:id]), status: :ok
      end
    end
  end

  def has_publishing_update # rubocop:disable Naming/PredicateName
    params_for_update = params
      .permit(:id, :internal_at, :published_at, :archived_at)
      .to_h
      .map { |k, v| [k.to_sym, v == '--now--' ? Time.zone.now : v] }
      .to_h

    model_update_render(klass, params_for_update)
  end
end
