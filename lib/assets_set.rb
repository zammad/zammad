# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'assets_set/proxy'

# The name AssetsSet combines the Assets term in Zammad with the Set class from the Ruby StdLib.
# Zammad Assets serve the purpose to limit requests to the REST API. For a requested object all
# related and relevant objects are collected recursively and then send to the client in one go.
# A Ruby Set implements a collection of unordered values with no duplicates.
#
# This class implements a collection of Zammad Assets with no duplicates.
# This is done by having two structures:
#
# 1st: The actual Assets Hash (e.g. `assets[model_name][object_id] = object_attributes`)
# 2nd: A lookup table for keeping track which elements were added to the actual Assets Hash
#
# The actual Assets Hash should be flushed after sending it to the client. This will keep the
# lookup table untouched. The next time a object that was already send to the client
# should be added to the actual Assets Hash the lookup table will recognize the object
# and will prevent the addition to the actual Assets Hash.
# This way Assets will be send only once to the client for the lifetime of a AssetsSet instance.
class AssetsSet < SimpleDelegator

  # This method overwrites the SimpleDelegator initializer
  # to be able to have the actual Assets Hash as an optional argument.
  def initialize(assets = {})
    super(assets)
  end

  # This method initializes the the global lookup table.
  # Each (accessed) Model gets it's own sub structure in it.
  def lookup_table
    @lookup_table ||= {}
  end

  # This method flushes the actual Assets Hash.
  def flush
    __setobj__({})
  end

  # This method intercepts `assets[model_name]` calls by registering a AssetsSet::Proxy.
  # Instead of creating an entry in the actual Assets Hash a AssetsSet::Proxy.
  # See AssetsSet::Proxy for further information.
  # Existing proxies will be reused.
  def [](model)
    __getobj__[model] ||= proxy(model)
  end

  # This method is used to convert the AssetsSet into a regular Hash which then can be send to the client.
  # It cleans up empty Model sub structures in the internal structure.
  def to_h
    super.delete_if { |_model, assets| assets.blank? }.transform_values!(&:to_h)
  end

  private

  def proxy(model)
    lookup_table[model] ||= {}

    ::AssetsSet::Proxy.new.tap do |proxy|
      proxy.lookup_table = lookup_table[model]
    end
  end
end
