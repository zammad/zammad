# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationModel::CanLookupSearchIndexAttributes
  extend ActiveSupport::Concern

=begin

This function return the attributes for the elastic search with relation hash values.

It can be run with parameter include_references: false to skip the relational hashes to prevent endless loops.

  ticket = Ticket.find(3)
  attributes = ticket.search_index_attribute_lookup
  attributes = ticket.search_index_attribute_lookup(include_references: false)

returns

  attributes # object with lookup data

=end

  def search_index_attribute_lookup(include_references: true)
    attributes = self.attributes
    self.attributes.each do |key, value|
      break if !include_references

      attribute_name = key.to_s

      # ignore standard attribute if needed
      if self.class.search_index_attribute_ignored?(attribute_name)
        attributes.delete(attribute_name)
        next
      end

      # need value for reference data
      next if !value

      # check if we have a referenced object which we could include here
      next if !search_index_attribute_method(attribute_name)

      # get referenced attribute name
      attribute_ref_name = self.class.search_index_attribute_ref_name(attribute_name)
      next if !attribute_ref_name

      # ignore referenced attributes if needed
      next if self.class.search_index_attribute_ignored?(attribute_ref_name)

      # get referenced attribute value
      value = search_index_value_by_attribute(attribute_name)
      next if !value

      # save name of ref object
      attributes[ attribute_ref_name ] = value
    end

    attributes
  end

=begin

This function returns the relational search index value based on the attribute name.

  organization = Organization.find(1)
  value = organization.search_index_value_by_attribute('organization_id')

returns

  value = {"name"=>"Zammad Foundation"}

=end

  def search_index_value_by_attribute(attribute_name = '')

    # get attribute name
    relation_class = search_index_attribute_method(attribute_name)
    return if !relation_class

    # lookup ref object
    relation_model = relation_class.lookup(id: attributes[attribute_name])
    return if !relation_model

    relation_model.search_index_attribute_lookup(include_references: false)
  end

=begin

This function returns the method for the relational search index attribute.

  method = Ticket.new.search_index_attribute_method('organization_id')

returns

  method = Organization (class)

=end

  def search_index_attribute_method(attribute_name = '')
    return if attribute_name[-3, 3] != '_id'

    attribute_name = attribute_name[ 0, attribute_name.length - 3 ]
    return if !respond_to?(attribute_name)

    send(attribute_name).class
  end

  class_methods do

=begin

This function returns the relational search index attribute name for the given class.

  attribute_ref_name = Organization.search_index_attribute_ref_name('user_id')

returns

  attribute_ref_name = 'user'

=end

    def search_index_attribute_ref_name(attribute_name)
      attribute_name[ 0, attribute_name.length - 3 ]
    end

=begin

This function returns if a search index attribute should be ignored.

  ignored = Ticket.search_index_attribute_ignored?('organization_id')

returns

  ignored = false

=end

    def search_index_attribute_ignored?(attribute_name = '')
      ignored_attributes = instance_variable_get(:@search_index_attributes_ignored) || []
      return if ignored_attributes.blank?

      ignored_attributes.include?(attribute_name.to_sym)
    end
  end
end
