# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module User::OutOfOffice
  extend ActiveSupport::Concern

  included do
    validates_with Validations::OutOfOfficeValidator

    belongs_to :out_of_office_replacement, class_name: 'User', optional: true

    scope :out_of_office, lambda { |user, interval_start = Time.zone.today, interval_end = Time.zone.today|
      where(active: true, out_of_office: true, out_of_office_replacement_id: user)
        .where('out_of_office_start_at <= ? AND out_of_office_end_at >= ?', interval_start, interval_end)
    }
  end

=begin

check if user is in role

  user = User.find(123)
  result = user.out_of_office?

returns

  result = true|false

=end

  def out_of_office?
    return false if out_of_office != true
    return false if out_of_office_start_at.blank?
    return false if out_of_office_end_at.blank?

    Time.use_zone(Setting.get('timezone_default')) do
      start  = out_of_office_start_at.beginning_of_day
      finish = out_of_office_end_at.end_of_day

      Time.zone.now.between? start, finish
    end
  end

=begin

check if user is in role

  user = User.find(123)
  result = user.out_of_office_agent

returns

  result = user_model

=end

  def out_of_office_agent(loop_user_ids: [], stack_depth: 10)
    return if !out_of_office?
    return if out_of_office_replacement_id.blank?

    if stack_depth.zero?
      Rails.logger.warn("Found more than 10 replacement levels for agent #{self}.")
      return self
    end

    user = User.find_by(id: out_of_office_replacement_id)

    # stop if users are occuring multiple times to prevent endless loops
    return user if loop_user_ids.include?(out_of_office_replacement_id)

    loop_user_ids |= [out_of_office_replacement_id]

    ooo_agent = user.out_of_office_agent(loop_user_ids: loop_user_ids, stack_depth: stack_depth - 1)
    return ooo_agent if ooo_agent.present?

    user
  end

=begin

gets users where user is replacement

  user = User.find(123)
  result = user.out_of_office_agent_of

returns

  result = [user_model1, user_model2]

=end

  def out_of_office_agent_of
    self.class.where(id: out_of_office_agent_of_recursive(user_id: id))
  end

  def someones_out_of_office_replacement?
    self.class.out_of_office(self).exists?
  end

  private

  def out_of_office_agent_of_recursive(user_id:, result: [])
    self.class.out_of_office(user_id).each do |user|

      # stop if users are occuring multiple times to prevent endless loops
      break if result.include?(user.id)

      result |= [user.id]
      result |= out_of_office_agent_of_recursive(user_id: user.id, result: result)
    end

    result
  end
end
