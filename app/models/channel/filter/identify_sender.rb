# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::IdentifySender

  def self.run(_channel, mail, _transaction_params)

    customer_user_id = mail[ :'x-zammad-ticket-customer_id' ]
    customer_user = nil
    if customer_user_id.present?
      customer_user = User.lookup(id: customer_user_id)
      if customer_user
        Rails.logger.debug { "Took customer form x-zammad-ticket-customer_id header '#{customer_user_id}'." }
      else
        Rails.logger.debug { "Invalid x-zammad-ticket-customer_id header '#{customer_user_id}', no such user - take user from 'from'-header." }
      end
    end

    # check if sender exists in database
    if !customer_user && mail[ :'x-zammad-customer-login' ].present?
      customer_user = User.find_by(login: mail[ :'x-zammad-customer-login' ])
    end
    if !customer_user && mail[ :'x-zammad-customer-email' ].present?
      customer_user = User.find_by(email: mail[ :'x-zammad-customer-email' ])
    end

    # get correct customer
    if !customer_user && Setting.get('postmaster_sender_is_agent_search_for_customer') == true && mail[ :'x-zammad-ticket-create-article-sender' ] == 'Agent'
      # get first recipient and set customer
      begin
        to = :'raw-to'
        if mail[to]&.addrs
          items = mail[to].addrs
          items.each do |item|

            # skip if recipient is system email
            next if EmailAddress.exists?(email: item.address.downcase)

            customer_user = user_create(
              login:     item.address,
              firstname: item.display_name,
              email:     item.address,
            )
            break
          end
        end
      rescue => e
        Rails.logger.error "SenderIsSystemAddress: ##{e.inspect}"
      end
    end

    # take regular from as customer
    if !customer_user
      customer_user = user_create(
        login:     mail[ :'x-zammad-customer-login' ] || mail[ :'x-zammad-customer-email' ] || mail[:from_email],
        firstname: mail[ :'x-zammad-customer-firstname' ] || mail[:from_display_name],
        lastname:  mail[ :'x-zammad-customer-lastname' ],
        email:     mail[ :'x-zammad-customer-email' ] || mail[:from_email],
      )
    end

    create_recipients(mail)
    mail[ :'x-zammad-ticket-customer_id' ] = customer_user.id

    # find session user
    session_user_id = mail[ :'x-zammad-session-user-id' ]
    session_user = nil
    if session_user_id.present?
      session_user = User.lookup(id: session_user_id)
      if session_user
        Rails.logger.debug { "Took session form x-zammad-session-user-id header '#{session_user_id}'." }
      else
        Rails.logger.debug { "Invalid x-zammad-session-user-id header '#{session_user_id}', no such user - take user from 'from'-header." }
      end
    end
    if !session_user
      session_user = user_create(
        login:     mail[:from_email],
        firstname: mail[:from_display_name],
        lastname:  '',
        email:     mail[:from_email],
      )
    end
    if session_user
      mail[ :'x-zammad-session-user-id' ] = session_user.id
    end

    true
  end

  # create to and cc user
  def self.create_recipients(mail)
    max_count = 40
    current_count = 0
    %w[raw-to raw-cc].each do |item|
      next if mail[item.to_sym].blank?

      begin
        items = mail[item.to_sym].addrs
        next if items.blank?

        items.each do |address_data|
          email_address = sanitize_email(address_data.address)
          next if email_address.blank?

          email_address_validation = EmailAddressValidation.new(email_address)
          next if !email_address_validation.valid_format?

          user_create(
            firstname: address_data.display_name,
            lastname:  '',
            email:     email_address,
          )
          current_count += 1
          return false if current_count == max_count
        end
      rescue => e
        # parse not parsable fields by mail gem like
        #  - Max Kohl | [example.com] <kohl@example.com>
        #  - Max Kohl <max.kohl <max.kohl@example.com>
        Rails.logger.error e
        Rails.logger.error "try it by my self (#{item}): #{mail[item.to_sym]}"
        recipients = mail[item.to_sym].to_s.split(',')
        recipients.each do |recipient|
          address = nil
          display_name = nil
          if recipient =~ %r{.*<(.+?)>}
            address = $1
          end
          if recipient =~ %r{^(.+?)<(.+?)>}
            display_name = $1
          end

          next if address.blank?

          address = sanitize_email(address)

          email_address_validation = EmailAddressValidation.new(address)
          next if !email_address_validation.valid_format?

          user_create(
            firstname: display_name,
            lastname:  '',
            email:     address,
          )
          current_count += 1
          return false if current_count == max_count
        end
      end
    end
  end

  def self.user_create(attrs, role_ids = nil)
    populate_attributes!(attrs, role_ids: role_ids)

    if (user = User.find_by('email = :email OR login = :email', attrs))
      user.update!(attrs.slice(:firstname)) if user.no_name? && attrs[:firstname].present?
    elsif (user = User.create!(attrs))
      user.update!(updated_by_id: user.id, created_by_id: user.id)
    end

    user
  end

  def self.populate_attributes!(attrs, **extras)
    if attrs[:email].match?(%r{\S\s+\S}) || attrs[:email].match?(%r{^<|>$})
      attrs[:preferences] = { mail_delivery_failed:        true,
                              mail_delivery_failed_reason: 'invalid email',
                              mail_delivery_failed_data:   Time.zone.now }
    end

    attrs.merge!(
      email:         sanitize_email(attrs[:email]),
      firstname:     sanitize_name(attrs[:firstname]),
      lastname:      sanitize_name(attrs[:lastname]),
      password:      '',
      active:        true,
      role_ids:      extras[:role_ids] || Role.signup_role_ids,
      updated_by_id: 1,
      created_by_id: 1
    )
  end

  def self.sanitize_name(string)
    return '' if string.nil?

    string.strip
          .delete('"')
          .delete_prefix("'")
          .delete_suffix("'")
          .gsub(%r{.+?\s\(.+?\)$}, '')
  end

  def self.sanitize_email(string)
    string += '@local' if string.exclude?('@')

    string.downcase
          .strip
          .delete('"')
          .delete("'")
          .delete(' ') # see https://github.com/zammad/zammad/issues/2254
          .sub(%r{^<|>$}, '')        # see https://github.com/zammad/zammad/issues/2254
          .sub(%r{\A'(.*)'\z}, '\1') # see https://github.com/zammad/zammad/issues/2154
          .gsub(%r{\s}, '')          # see https://github.com/zammad/zammad/issues/2198
          .delete_suffix('.')
  end

end
