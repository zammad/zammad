# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# This class defines a Proxy for accessing objects inside of a AssetsSet Model sub structure.
#
# The Zammad Assets logic works by having an Assets Hash that contains a sub structure for
# each model that is relevant. Before an object gets added to the Model sub structure the
# Model sub structure is checked for the presence of the object by its id. If the object is
# already present it will be skipped. However, if the model is not yet present in the matching
# Model sub structure the Zammad Assets will be collected and added.
#
# We make use of this lookup / add if not present functionality by intercepting calls to the
# actual Assets Hash.
#
# If an object is not yet present in the Model sub structure and should be added
# it will added to the lookup table of the AssetsSet first. After that the object will
# be stored to the actual Assets Hash.
#
# The next time a lookup for an object in the Model sub structure is performed it will find the
# actual object data. However, if the actual Assets Hash is send to the client and the AssetsSet
# is flushed the lookup table is still present. The next time a lookup for an object in the
# Model sub is performed it will NOT find the actual object data. In this case a fall back
# to the lookup table will be performed which will will just return `true` to satisfy the
# "is present" condition
class AssetsSet < SimpleDelegator
  class Proxy < SimpleDelegator

    attr_accessor :lookup_table

    # This method overwrites the SimpleDelegator initializer
    # to be able to have the actual Assets Hash as an optional argument.
    def initialize(assets = {})
      super(assets)
    end

    # This method intercepts `assets[model_name][object_id]` calls and return the actual objects data.
    # If the object it not present the lookup table of the AssetsSet will be queried.
    # If the object was present before a previously performed `flush` it will return true and
    # satisfy the "is present" condition in the `assets` of the given model.
    # If the object is not and never was present the `assets` logic will be performed as normal.
    def [](id)
      __getobj__[id] || lookup_table[id]
    end

    # This method intercepts `assets[model_name][object_id] = object_attributes` calls.
    # It stores an entry in the lookup the of the AssetsSet and then performs the regular call
    # to store the data in the actual Assets Hash Model sub structure.
    def []=(id, _value)
      lookup_table[id] = true
      super
    end
  end
end
