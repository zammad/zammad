# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::IdentifySender

  def self.run(_channel, mail)

    customer_user_id = mail[ 'x-zammad-ticket-customer_id'.to_sym ]
    customer_user = nil
    if customer_user_id.present?
      customer_user = User.lookup(id: customer_user_id)
      if customer_user
        Rails.logger.debug "Took customer form x-zammad-ticket-customer_id header '#{customer_user_id}'."
      else
        Rails.logger.debug "Invalid x-zammad-ticket-customer_id header '#{customer_user_id}', no such user - take user from 'from'-header."
      end
    end

    # check if sender exists in database
    if !customer_user && mail[ 'x-zammad-customer-login'.to_sym ].present?
      customer_user = User.find_by(login: mail[ 'x-zammad-customer-login'.to_sym ])
    end
    if !customer_user && mail[ 'x-zammad-customer-email'.to_sym ].present?
      customer_user = User.find_by(email: mail[ 'x-zammad-customer-email'.to_sym ])
    end
    if !customer_user

      # get correct customer
      if mail[ 'x-zammad-ticket-create-article-sender'.to_sym ] == 'Agent'

        # get first recipient and set customer
        begin
          to = 'raw-to'.to_sym
          if mail[to] && mail[to].addrs
            items = mail[to].addrs
            items.each { |item|

              # skip if recipient is system email
              next if EmailAddress.find_by(email: item.address.downcase)

              customer_user = user_create(
                login: item.address,
                firstname: item.display_name,
                email: item.address,
              )
              break
            }
          end
        rescue => e
          Rails.logger.error 'ERROR: SenderIsSystemAddress: ' + e.inspect
        end
      end
      if !customer_user
        customer_user = user_create(
          login: mail[ 'x-zammad-customer-login'.to_sym ] || mail[ 'x-zammad-customer-email'.to_sym ] || mail[:from_email],
          firstname: mail[ 'x-zammad-customer-firstname'.to_sym ] || mail[:from_display_name],
          lastname: mail[ 'x-zammad-customer-lastname'.to_sym ],
          email: mail[ 'x-zammad-customer-email'.to_sym ] || mail[:from_email],
        )
      end
    end
    create_recipients(mail)
    mail[ 'x-zammad-ticket-customer_id'.to_sym ] = customer_user.id

    # find session user
    session_user_id = mail[ 'x-zammad-session-user-id'.to_sym ]
    session_user = nil
    if session_user_id.present?
      session_user = User.lookup(id: session_user_id)
      if session_user
        Rails.logger.debug "Took session form x-zammad-session-user-id header '#{session_user_id}'."
      else
        Rails.logger.debug "Invalid x-zammad-session-user-id header '#{session_user_id}', no such user - take user from 'from'-header."
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
  end

  # create to and cc user
  def self.create_recipients(mail)
    ['raw-to', 'raw-cc'].each { |item|
      next if !mail[item.to_sym]
      begin
        next if !mail[item.to_sym].addrs
        items = mail[item.to_sym].addrs
        items.each { |address_data|
          next if address_data.address.blank?
          user_create(
            firstname: address_data.display_name,
            lastname: '',
            email: address_data.address,
          )
        }
      rescue => e
        # parse not parseable fields by mail gem like
        #  - Max Kohl | [example.com] <kohl@example.com>
        #  - Max Kohl <max.kohl <max.kohl@example.com>
        Rails.logger.error 'ERROR: ' + e.inspect
        Rails.logger.error "ERROR: try it by my self (#{item}): #{mail[item.to_sym]}"
        recipients = mail[item.to_sym].to_s.split(',')
        recipients.each { |recipient|
          address = nil
          display_name = nil
          if recipient =~ /.*<(.+?)>/
            address = $1
          end
          if recipient =~ /^(.+?)<(.+?)>/
            display_name = $1
          end
          next if address.blank?
          user_create(
            firstname: display_name,
            lastname: '',
            email: address,
          )
        }
      end
    }
  end

  def self.user_create(data)
    if data[:email] !~ /@/
      data[:email] += '@local'
    end
    user = User.find_by(email: data[:email].downcase)
    if !user
      user = User.find_by(login: data[:email].downcase)
    end

    # check if firstname or lastname need to be updated
    if user
      if user.firstname.blank? && user.lastname.blank?
        if data[:firstname].present?
          data[:firstname] = cleanup_name(data[:firstname])
          user.update_attributes(
            firstname: data[:firstname]
          )
        end
      end
      return user
    end

    # create new user
    role_ids = Role.signup_role_ids

    # fillup
    %w(firstname lastname).each { |item|
      if data[item.to_sym].nil?
        data[item.to_sym] = ''
      end
      data[item.to_sym] = cleanup_name(data[item.to_sym])
    }
    data[:password]      = ''
    data[:active]        = true
    data[:role_ids]      = role_ids
    data[:updated_by_id] = 1
    data[:created_by_id] = 1

    user = User.create(data)
    user.update_attributes(
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

end
