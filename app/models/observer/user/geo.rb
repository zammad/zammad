# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::User::Geo < ActiveRecord::Observer
  observe 'user'

  def before_create(record)
    check_geo(record)
    true
  end

  def before_update(record)
    check_geo(record)
    true
  end

  # check if geo need to be updated
  def check_geo(record)

    location = %w[address street zip city country]

    # check if geo update is needed based on old/new location
    if record.id
      current = User.find_by(id: record.id)
      return if !current

      current_location = {}
      location.each do |item|
        current_location[item] = current[item]
      end
    end

    # get full address
    next_location = {}
    location.each do |item|
      next_location[item] = record[item]
    end

    # return if address hasn't changed and geo data is already available
    return if (current_location == next_location) && record.preferences['lat'] && record.preferences['lng']

    # geo update
    geo_update(record)
  end

  # update geo data of user
  def geo_update(record)
    address = ''
    location = %w[address street zip city country]
    location.each do |item|
      next if record[item].blank?

      if address.present?
        address += ', '
      end
      address += record[item]
    end

    # return if no address is given
    return if address.blank?

    # lookup
    latlng = Service::GeoLocation.geocode(address)
    return if !latlng

    # store data
    record.preferences['lat'] = latlng[0]
    record.preferences['lng'] = latlng[1]
  end
end
