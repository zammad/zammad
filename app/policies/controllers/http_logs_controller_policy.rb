# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::HttpLogsControllerPolicy < Controllers::ApplicationControllerPolicy
  def index?
    permitted?
  end

  def create?
    permitted?
  end

  private

  def permitted?
    HttpLogPolicy.new(user, record).permitted?
  end
end
