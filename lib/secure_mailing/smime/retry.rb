# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SecureMailing::SMIME::Retry < SecureMailing::Backend::Handler

  def initialize(article)
    super()
    @article = article
  end

  def process
    return existing_result if already_processed?

    save_result if retry_succeeded?
    retry_result
  end

  def signature_checked?
    @signature_checked ||= existing_result&.dig('sign', 'success') || false
  end

  def decrypted?
    @decrypted ||= existing_result&.dig('encryption', 'success') || false
  end

  def already_processed?
    signature_checked? && decrypted?
  end

  def existing_result
    @article.preferences['security']
  end

  def mail
    @mail ||= begin
      raw_mail = @article.as_raw.store_file.content
      Channel::EmailParser.new.parse(raw_mail).tap do |parsed|
        SecureMailing.incoming(parsed)
      end
    end
  end

  def retry_result
    @retry_result ||= mail['x-zammad-article-preferences']['security']
  end

  def signature_found?
    return false if signature_checked?

    retry_result['sign']['success']
  end

  def decryption_succeeded?
    return false if decrypted?

    retry_result['encryption']['success']
  end

  def retry_succeeded?
    return true if signature_found?

    decryption_succeeded?
  end

  def save_result
    save_decrypted if decryption_succeeded?
    @article.preferences['security'] = retry_result
    @article.save!
  end

  def save_decrypted
    @article.content_type = mail['content_type']
    @article.body         = mail['body']

    Store.remove(
      object: 'Ticket::Article',
      o_id:   @article.id,
    )

    mail[:attachments]&.each do |attachment|
      filename = attachment[:filename].force_encoding('utf-8')
      if !filename.force_encoding('UTF-8').valid_encoding?
        filename = filename.utf8_encode(fallback: :read_as_sanitized_binary)
      end
      Store.add(
        object:        'Ticket::Article',
        o_id:          @article.id,
        data:          attachment[:data],
        filename:      filename,
        preferences:   attachment[:preferences],
        created_by_id: @article.created_by_id,
      )
    end
  end
end
