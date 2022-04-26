# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class FormSchema::FieldResolver

  class << self

    def field_for_object_attribute(context:, attribute:)

      resolver_method = :"field_for_oa_type_#{attribute.data_type}"
      if respond_to?(resolver_method)
        return send(resolver_method, context: context, attribute: attribute)
      end

      raise "Cannot resolve object attribute field type #{attribute.data_type}."
    end

    def base_attributes(context:, attribute:)
      {
        context: context,
        name:    attribute[:name],
        label:   attribute[:display],
      }.tap do |result|
        default = attribute[:data_option]['default']
        result[:value] = default if !default.nil?
      end
    end

    def field_for_oa_type_input(context:, attribute:)
      case attribute[:data_option]['type']
      when 'password'
        FormSchema::Field::Password.new(
          **base_attributes(context: context, attribute: attribute),
          maxlength: attribute[:data_option]['maxlength']
        )
      when 'tel'
        FormSchema::Field::Telephone.new(
          **base_attributes(context: context, attribute: attribute),
          maxlength: attribute[:data_option]['maxlength']
        )
      when 'email'
        FormSchema::Field::Email.new(
          **base_attributes(context: context, attribute: attribute),
        )
      # TODO: what about the 'url' field type?
      # when 'url'
      else
        FormSchema::Field::Text.new(
          **base_attributes(context: context, attribute: attribute),
          maxlength: attribute[:data_option]['maxlength']
          # TODO: this and other field types have a 'link template' attribute, what to do about it?
        )
      end
    end

    def field_for_oa_type_textarea(context:, attribute:)
      FormSchema::Field::Textarea.new(
        **base_attributes(context: context, attribute: attribute),
        maxlength: attribute[:data_option]['maxlength']
      )
    end

    def field_for_oa_type_richtext(context:, attribute:)
      FormSchema::Field::Editor.new(
        **base_attributes(context: context, attribute: attribute),
        # TODO: the OA has a maxlength attribute, but Field::Editor does not support that yet.
        # maxlength: attribute[:data_option]['maxlength']
      )
    end

    def field_for_oa_type_select(context:, attribute:)
      options = attribute[:data_option][:options]
      mapped_options = if options.is_a? Array
                         options.map { |e| { value: e['value'], label: e['name'] } }
                       else
                         options.keys.map { |key| { value: key, label: options[key] } }
                       end
      additional_attributes = { options: mapped_options }
      additional_attributes[:multiple] = true if attribute.data_type.eql?('multiselect')
      FormSchema::Field::Select.new(
        **base_attributes(context: context, attribute: attribute),
        **additional_attributes,
      )
    end

    alias field_for_oa_type_multiselect field_for_oa_type_select
    # TODO: what about the tree (multi)select field type?

    def field_for_oa_type_boolean(context:, attribute:)
      options = attribute[:data_option][:options]
      FormSchema::Field::Select.new(
        **base_attributes(context: context, attribute: attribute),
        options: [
          { value: true, label: options[true] },
          { value: false, label: options[false] },
        ]
      )
    end

    def field_for_oa_type_integer(context:, attribute:)
      FormSchema::Field::Number.new(
        **base_attributes(context: context, attribute: attribute),
        min: attribute[:data_option][:min],
        max: attribute[:data_option][:max],
      )
    end

    def field_for_oa_type_date(context:, attribute:)
      FormSchema::Field::Date.new(
        **base_attributes(context: context, attribute: attribute),
        # TODO: what about the :diff attribute?
      )
    end

    def field_for_oa_type_datetime(context:, attribute:)
      FormSchema::Field::Datetime.new(
        **base_attributes(context: context, attribute: attribute),
        # TODO: there are also :diff, :future and :past attributes, what about them?
      )
    end
  end
end
