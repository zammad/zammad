# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::IdentifySender

  def self.run(_channel, mail)

    customer_user_id = mail[ 'x-zammad-ticket-customer_id'.to_sym ]
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
    if !customer_user && mail[ 'x-zammad-customer-login'.to_sym ].present?
      customer_user = User.find_by(login: mail[ 'x-zammad-customer-login'.to_sym ])
    end
    if !customer_user && mail[ 'x-zammad-customer-email'.to_sym ].present?
      customer_user = User.find_by(email: mail[ 'x-zammad-customer-email'.to_sym ])
    end

    # get correct customer
    if !customer_user && Setting.get('postmaster_sender_is_agent_search_for_customer') == true
      if mail[ 'x-zammad-ticket-create-article-sender'.to_sym ] == 'Agent'

        # get first recipient and set customer
        begin
          to = 'raw-to'.to_sym
          if mail[to]&.addrs
            items = mail[to].addrs
            items.each do |item|

              # skip if recipient is system email
              next if EmailAddress.find_by(email: item.address.downcase)

              customer_user = user_create(
                login: item.address,
                firstname: item.display_name,
                email: item.address,
              )
              break
            end
          end
        rescue => e
          Rails.logger.error "SenderIsSystemAddress: ##{e.inspect}"
        end
      end
    end

    # take regular from as customer
    if !customer_user
      customer_user = user_create(
        login: mail[ 'x-zammad-customer-login'.to_sym ] || mail[ 'x-zammad-customer-email'.to_sym ] || mail[:from_email],
        firstname: mail[ 'x-zammad-customer-firstname'.to_sym ] || mail[:from_display_name],
        lastname: mail[ 'x-zammad-customer-lastname'.to_sym ],
        email: mail[ 'x-zammad-customer-email'.to_sym ] || mail[:from_email],
      )
    end

    create_recipients(mail)
    mail[ 'x-zammad-ticket-customer_id'.to_sym ] = customer_user.id

    # find session user
    session_user_id = mail[ 'x-zammad-session-user-id'.to_sym ]
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
        login: mail[:from_email],
        firstname: mail[:from_display_name],
        lastname: '',
        email: mail[:from_email],
      )
    end
    if session_user
      mail[ 'x-zammad-session-user-id'.to_sym ] = session_user.id
    end

    true
  end

  # create to and cc user
  def self.create_recipients(mail)
    max_count = 40
    current_count = 0
    ['raw-to', 'raw-cc'].each do |item|
      next if mail[item.to_sym].blank?
      begin
        items = mail[item.to_sym].addrs
        next if items.blank?
        items.each do |address_data|
          email_address = address_data.address
          next if email_address.blank?
          next if email_address !~ /@/
          next if email_address.match?(/\s/)
          user_create(
            firstname: address_data.display_name,
            lastname: '',
            email: email_address,
          )
          current_count += 1
          return false if current_count == max_count
        end
      rescue => e
        # parse not parseable fields by mail gem like
        #  - Max Kohl | [example.com] <kohl@example.com>
        #  - Max Kohl <max.kohl <max.kohl@example.com>
        Rails.logger.error 'ERROR: ' + e.inspect
        Rails.logger.error "ERROR: try it by my self (#{item}): #{mail[item.to_sym]}"
        recipients = mail[item.to_sym].to_s.split(',')
        recipients.each do |recipient|
          address = nil
          display_name = nil
          if recipient =~ /.*<(.+?)>/
            address = $1
          end
          if recipient =~ /^(.+?)<(.+?)>/
            display_name = $1
          end
          next if address.blank?
          next if address !~ /@/
          next if address.match?(/\s/)
          user_create(
            firstname: display_name,
            lastname: '',
            email: address,
          )
          current_count += 1
          return false if current_count == max_count
        end
      end
    end
  end

  def self.user_create(data, role_ids = nil)
    data[:email] += '@local' if !data[:email].match?(/@/)
    data[:email] = cleanup_email(data[:email])
    user = User.find_by(email: data[:email]) ||
           User.find_by(login: data[:email])

    # check if firstname or lastname need to be updated
    if user
      if user.firstname.blank? && user.lastname.blank?
        if data[:firstname].present?
          data[:firstname] = cleanup_name(data[:firstname])
          user.update!(
            firstname: data[:firstname]
          )
        end
      end
      return user
    end

    # create new user
    role_ids ||= Role.signup_role_ids

    # fillup
    %w[firstname lastname].each do |item|
      if data[item.to_sym].nil?
        data[item.to_sym] = ''
      end
      data[item.to_sym] = cleanup_name(data[item.to_sym])
    end
    data[:password]      = ''
    data[:active]        = true
    data[:role_ids]      = role_ids
    data[:updated_by_id] = 1
    data[:created_by_id] = 1

    user = User.create!(data)
    user.update!(
      updated_by_id: user.id,
      created_by_id: user.id,
    )
    user
  end

  def self.cleanup_name(string)
    string.strip!
    string.delete!('"')
    string.gsub!(/^'/, '')
    string.gsub!(/'$/, '')
    string.gsub!(/.+?\s\(.+?\)$/, '')
    string
  end

  def self.cleanup_email(string)
    string = string.downcase
    string.strip!
    string.delete!('"')
    string
  end

end
