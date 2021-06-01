# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Channel::Driver::Smtp

=begin

  instance = Channel::Driver::Smtp.new
  instance.send(
    {
      host:                 'some.host',
      port:                 25,
      enable_starttls_auto: true, # optional
      openssl_verify_mode:  'none', # optional
      user:                 'someuser',
      password:             'somepass'
      authentication:       nil, # nil, autodetection - to use certain schema use 'plain', 'login', 'xoauth2' or 'cram_md5'
    },
    mail_attributes,
    notification
  )

=end

  def send(options, attr, notification = false)

    # return if we run import mode
    return if Setting.get('import_mode')

    # set smtp defaults
    if !options.key?(:port) || options[:port].blank?
      options[:port] = 25
    end
    if !options.key?(:ssl) && options[:port].to_i == 465
      options[:ssl] = true
    end
    if !options.key?(:domain)
      # set fqdn, if local fqdn - use domain of sender
      fqdn = Setting.get('fqdn')
      if fqdn =~ %r{(localhost|\.local^|\.loc^)}i && (attr['from'] || attr[:from])
        domain = Mail::Address.new(attr['from'] || attr[:from]).domain
        if domain
          fqdn = domain
        end
      end
      options[:domain] = fqdn
    end
    if !options.key?(:enable_starttls_auto)
      options[:enable_starttls_auto] = true
    end
    if !options.key?(:openssl_verify_mode)
      options[:openssl_verify_mode] = 'none'
    end

    # set system_bcc of config if defined
    system_bcc = Setting.get('system_bcc')
    email_address_validation = EmailAddressValidation.new(system_bcc)
    if system_bcc.present? && email_address_validation.valid_format?
      attr[:bcc] ||= ''
      attr[:bcc] += ', ' if attr[:bcc].present?
      attr[:bcc] += system_bcc
    end

    mail = Channel::EmailBuild.build(attr, notification)
    smtp_params = {
      openssl_verify_mode:  options[:openssl_verify_mode],
      address:              options[:host],
      port:                 options[:port],
      domain:               options[:domain],
      enable_starttls_auto: options[:enable_starttls_auto],
    }

    # set ssl if needed
    if options[:ssl].present?
      smtp_params[:ssl] = options[:ssl]
    end

    # add authentication only if needed
    if options[:user].present?
      smtp_params[:user_name] = options[:user]
      smtp_params[:password] = options[:password]
      smtp_params[:authentication] = options[:authentication]
    end
    mail.delivery_method :smtp, smtp_params
    mail.deliver
  end
end
