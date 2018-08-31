# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::BounceDeliveryTemporaryFailed

  def self.run(_channel, mail)
    return if !mail[:mail_instance]
    return if !mail[:attachments]
    return if mail[:mail_instance].action != 'delayed'
    return if mail[:mail_instance].retryable? != true
    return if mail[:mail_instance].error_status != '4.4.1'

    # if header is available, do change current ticket state
    mail['x-zammad-out-of-office'.to_sym] = true

    true
  end
end
