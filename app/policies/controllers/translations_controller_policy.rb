class Controllers::TranslationsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.translation')
end
