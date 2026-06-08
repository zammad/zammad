# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::BaseOperator < CoreWorkflow::Condition::Backend
  def check_operator
    raise 'check_operator missing!'
  end

  def match
    value.present? && condition_value.map(&:to_i).all? { |condition_int| value.map(&:to_i).all? { |value_int| value_int.send(check_operator, condition_int) } }
  end
end
