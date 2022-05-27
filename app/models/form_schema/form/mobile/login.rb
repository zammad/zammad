# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class FormSchema::Form::Mobile::Login < FormSchema::Form

  # demo code for field loading, WIP
  # def object_attribute_fields
  #   result = []
  #   # ::ObjectManager::Object.new('User').attributes(context.current_user, nil, data_only: false).map(&:attribute).each do |attribute|
  #   ::ObjectManager::Object.new('User').attributes(User.find(1), nil, data_only: false).map(&:attribute).each do |attribute|
  #     field = ::FormSchema::FieldResolver.field_for_object_attribute(context: context, attribute: attribute)
  #     result << field.schema if field
  #   end
  #   result
  # end

  def schema
    [
      FormSchema::Field::Text.new(
        context:     context,
        name:        'login',
        label:       __('Username / Email'),
        placeholder: __('Username / Email'),
        required:    true,
      ).schema,
      FormSchema::Field::Password.new(
        context:     context,
        name:        'password',
        label:       __('Password'),
        placeholder: __('Password'),
        required:    true,
      ).schema,
      # *object_attribute_fields,
      {
        isLayout: true,
        element:  'div',
        attrs:    {
          class: 'mt-2.5 flex grow items-center justify-between text-white',
        },
        children: [
          FormSchema::Field::Checkbox.new(
            context: context,
            label:   __('Remember me'),
            name:    'remember_me',
          ).schema,
          # TODO: this is only visible if config "user_lost_password" is true
          {
            isLayout:  true,
            component: 'CommonLink',
            props:     {
              class: 'text-right !text-white',
              link:  '/#password_reset',
            },
            children:  __('Forgot password?'),
          },
        ],
      },
    ]
  end
end
