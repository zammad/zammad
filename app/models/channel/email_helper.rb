# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Channel::EmailHelper
  PARTICIPANTS = %i[from to cc bcc reply-to return-path sender
                    resent-from resent-to resent-bcc
                    delivered-to x-original-to envelope-to].freeze

  def prepare_idn_outbound(mail)
    prepare_idn(mail, 'to_ascii')
  end

  def prepare_idn_inbound(mail)
    prepare_idn(mail, 'to_unicode')
  end

  private

  def prepare_idn(mail, action)
    PARTICIPANTS.each do |participant|
      next if !mail[participant]

      mail[participant] = mail[participant]
        .split(', ')
        .map { |address| EmailHelper::Idn.send(action, address) }
        .join(', ')
    end

    mail
  end
end
