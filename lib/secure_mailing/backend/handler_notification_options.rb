# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::Backend::HandlerNotificationOptions < SecureMailing::Backend::Handler

  attr_reader :from, :recipients, :perform, :security_options

  def initialize(from:, recipients:, perform:)
    super()

    @from       = from
    @recipients = recipients
    @perform    = perform

    @security_options = {
      type:       type,
      sign:       {
        success: false,
      },
      encryption: {
        success: false,
      },
    }
  end

  def process
    check_sign if perform[:sign]
    check_encrypt if perform[:encrypt]

    security_options
  end

  def check_sign(from)
    raise NotImplementedError
  end

  def check_encrypt(recipients)
    raise NotImplementedError
  end
end
