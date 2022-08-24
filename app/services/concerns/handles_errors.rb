# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module HandlesErrors
  extend ActiveSupport::Concern

  def error(message:)
    {
      message: message,
      error:   true
    }
  end
end
