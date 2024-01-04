# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::Backend::HandlerIncoming < SecureMailing::Backend::Handler
  attr_accessor :mail, :content_type

  def initialize(mail)
    super()

    @mail = mail
    @content_type = mail[:mail_instance].content_type
  end

  def process
    return if !process?

    initialize_article_preferences
    decrypt
    verify_signature
    log
  end

  def process?
    signed? || encrypted?
  end

  def initialize_article_preferences
    article_preferences[:security] = {
      type:       type,
      sign:       {
        success: false,
        comment: nil,
      },
      encryption: {
        success: false,
        comment: nil,
      }
    }
  end

  def article_preferences
    @article_preferences ||= begin
      key = :'x-zammad-article-preferences'
      mail[ key ] ||= {}
      mail[ key ]
    end
  end

  def signed?
    raise NotImplementedError
  end

  def encrypted?
    raise NotImplementedError
  end

  def decrypt
    raise NotImplementedError
  end

  def verify_signature
    raise NotImplementedError
  end

  def set_article_preferences(operation:, comment:, success: false)
    article_preferences[:security][operation] = {
      success: success,
      comment: comment,
    }
  end

  private

  def parse_decrypted_mail(decrypted_body)
    %w[Content-Type Content-Disposition Content-Transfer-Encoding Content-Description].each do |header|
      mail[:mail_instance].header[header] = nil
    end

    Channel::EmailParser.new.parse("#{mail[:mail_instance].header}#{decrypted_body}").each do |key, value|
      mail[key] = value
    end

    update_content_type
  end

  def update_content_type
    # By parsing the decrypted body, the content type might have changed.
    @content_type = mail[:mail_instance].content_type
  end

  def log
    %i[sign encryption].each do |action|
      result = log_result(action)

      next if result.blank?

      HttpLog.create(log_result(action))
    end
  end

  def log_result(action)
    result = article_preferences[:security][action]
    return if result.blank?

    if result[:success]
      status = 'success'
    elsif result[:comment].blank?
      # means not performed
      return
    else
      status = 'failed'
    end

    {
      direction:     'in',
      facility:      type,
      url:           "#{mail[:from]} -> #{mail[:to]}",
      status:        status,
      ip:            nil,
      request:       {
        message_id: mail[:message_id],
      },
      response:      article_preferences[:security],
      method:        action,
      created_by_id: 1,
      updated_by_id: 1,
    }
  end
end
