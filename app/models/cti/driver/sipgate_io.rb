# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Cti::Driver::SipgateIo < Cti::Driver::Base

  def config
    Setting.get('sipgate_config')
  end

  def push_open_ticket_screen_recipient

    # try to find answering which answered call
    user = nil

    # based on peer
    if @params['userId'].present?
      user_id = get_user_id_by_sipgate_user_id(@params['userId'])
      if user_id.present?
        user = if User.exists?(user_id)
                 User.find(user_id)
               else
                 User.find_by(email: user_id.downcase)
               end
      end
    end

    user
  end

  def load_voip_users
    return {} if @config.blank? || @config[:api_user].blank? || @config[:api_password].blank?

    list = Cache.read('sipgateUserList')
    return list if list

    url = 'https://api.sipgate.com/v2/users'

    response = UserAgent.get(
      url,
      {},
      {
        user:          @config[:api_user],
        password:      @config[:api_password],
        log:           {
          facility: 'sipagte.io',
        },
        json:          true,
        open_timeout:  4,
        read_timeout:  6,
        total_timeout: 6,
      },
    )

    if !response.success?
      Rails.logger.error "Can't fetch users from '#{url}', http code: #{response.code}"
      Cache.write('sipgateUserList', {}, { expires_in: 1.hour })
      return {}
    end
    result = response.data
    if result.blank?
      Rails.logger.error "Can't fetch users from '#{url}', result: #{response.inspect}"
      Cache.write('sipgateUserList', {}, { expires_in: 1.hour })
      return {}
    end
    if result.is_a?(Array) && (result['result'] == '-1' || result['result_code'] == 'error')
      Rails.logger.error "Can't fetch users from '#{url}', result: #{result.inspect}"
      Cache.write('sipgateUserList', {}, { expires_in: 1.hour })
      return {}
    end
    if !result.is_a?(Hash)
      Rails.logger.error "Can't fetch users from '#{url}', result: #{result.inspect}"
      Cache.write('sipgateUserList', {}, { expires_in: 1.hour })
      return {}
    end
    if result['items'].blank?
      Rails.logger.error "Can't fetch users from '#{url}', no items found, result: #{result.inspect}"
      Cache.write('sipgateUserList', {}, { expires_in: 1.hour })
      return {}
    end

    list = {}
    items = %w[firstname lastname email]
    result['items'].each do |entry|
      next if entry['id'].blank?

      name = ''
      items.each do |item|
        next if entry[item].blank?

        name += ' ' if name.present?
        name += entry[item]
      end

      list[entry['id']] = name
    end
    Cache.write('sipgateUserList', list, { expires_in: 24.hours })
    list
  end

  def get_user_id_by_sipgate_user_id(user_id)
    return if @config.blank? || @config[:user_remote_map].blank?

    @config[:user_remote_map].each do |row|
      next if row[:user_id].blank?
      return row[:user_id] if row[:remote_user_id] == user_id
    end

    nil
  end

end
