# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Perform geo data lookup on user changes.
module User::PerformsGeoLookup
  extend ActiveSupport::Concern

  included do
    before_create :user_check_geo_location
    before_update :user_check_geo_location
  end

  private

  def user_check_geo_location

    location = %w[address street zip city country]

    # check if geo update is needed based on old/new location
    if id
      current = User.find_by(id: id)
      return if !current

      current_location = {}
      location.each do |item|
        current_location[item] = current[item]
      end
    end

    # get full address
    next_location = {}
    location.each do |item|
      next_location[item] = attributes[item]
    end

    # return if address hasn't changed and geo data is already available
    return if (current_location == next_location) && preferences['lat'] && preferences['lng']

    # geo update
    user_update_geo_location
  end

  def user_update_geo_location
    address = ''
    location = %w[address street zip city country]
    location.each do |item|
      next if attributes[item].blank?

      if address.present?
        address += ', '
      end
      address += attributes[item]
    end

    # return if no address is given
    return if address.blank?

    # lookup
    latlng = Service::GeoLocation.geocode(address)

    return if !latlng

    # store data
    preferences['lat'] = latlng[0]
    preferences['lng'] = latlng[1]
  end
end
