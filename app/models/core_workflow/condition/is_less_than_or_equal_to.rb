# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::IsLessThanOrEqualTo < CoreWorkflow::Condition::BaseOperator
  def check_operator
    :<=
  end
end
