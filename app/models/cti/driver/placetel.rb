# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Cti::Driver::Placetel < Cti::Driver::Base

  def config
    Setting.get('placetel_config')
  end

  def mapping(params)

    # do event mapping
    case params['event']
    when 'IncomingCall'
      params['direction'] = 'in'
      params['event'] = 'newCall'
    when 'HungUp'
      params['event'] = 'hangup'
    when 'OutgoingCall'
      params['direction'] = 'out'
      params['event'] = 'newCall'
    when 'CallAccepted'
      params['event'] = 'answer'
    end

    # lookup current direction if not given
    if params['direction'].blank?
      entry = Cti::Log.find_by(call_id: params[:call_id])
      if entry
        params['direction'] = entry.direction
      end
    end

    # lookup caller if not given
    if params['user'].blank?
      # by from parameter for outgoing calls
      if params['direction'] == 'out' && params['from']&.include?('@')
        params['user'] = get_voip_user_by_peer(params['from'])
      end

      # by peer parameter for incoming calls
      if params['direction'] == 'in' && params['peer'].present?
        params['user'] = get_voip_user_by_peer(params['peer'])
      end
    end

    # do case mapping
    case params['type']
    when 'missed'
      params['cause'] = 'cancel'
    when 'voicemail'
      params['cause'] = 'voicemail'
    when 'blocked'
      params['cause'] = 'blocked'
    when 'accepted'
      params['cause'] = 'normalClearing'
    end

    params
  end

  def push_open_ticket_screen_recipient

    # try to find answering which answered call
    user = nil

    # based on peer
    if @params['peer'].present?
      user_id = get_user_id_by_peer(@params['peer'])
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

  def get_voip_user_by_peer(peer)
    load_voip_users[peer]
  end

  def load_voip_users
    return {} if @config.blank? || @config[:api_token].blank?

    list = Cache.read('placetelGetVoipUsers')
    return list if list

    response = UserAgent.post(
      'https://api.placetel.de/api/getVoIPUsers.json',
      {
        api_key: @config[:api_token],
      },
      {
        log:           {
          facility: 'placetel',
        },
        json:          true,
        open_timeout:  4,
        read_timeout:  6,
        total_timeout: 6,
      },
    )

    if !response.success?
      Rails.logger.error "Can't fetch getVoipUsers from '#{url}', http code: #{response.code}"
      Cache.write('placetelGetVoipUsers', {}, { expires_in: 1.hour })
      return {}
    end
    result = response.data
    if result.blank?
      Rails.logger.error "Can't fetch getVoipUsers from '#{url}', result: #{response.inspect}"
      Cache.write('placetelGetVoipUsers', {}, { expires_in: 1.hour })
      return {}
    end
    if result.is_a?(Hash) && (result['result'] == '-1' || result['result_code'] == 'error')
      Rails.logger.error "Can't fetch getVoipUsers from '#{url}', result: #{result.inspect}"
      Cache.write('placetelGetVoipUsers', {}, { expires_in: 1.hour })
      return {}
    end
    if !result.is_a?(Array)
      Rails.logger.error "Can't fetch getVoipUsers from '#{url}', result: #{result.inspect}"
      Cache.write('placetelGetVoipUsers', {}, { expires_in: 1.hour })
      return {}
    end

    list = {}
    result.each do |entry|
      next if entry['name'].blank?

      if entry['uid'].present?
        list[entry['uid']] = entry['name']
      end
      next if entry['uid2'].blank?

      list[entry['uid2']] = entry['name']
    end
    Cache.write('placetelGetVoipUsers', list, { expires_in: 24.hours })
    list
  end

  def get_user_id_by_peer(peer)
    return if @config.blank? || @config[:user_device_map].blank?

    @config[:user_device_map].each do |row|
      next if row[:user_id].blank?
      return row[:user_id] if row[:device_id] == peer
    end

    nil
  end

end
