# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class TwoFactorMethodType < BaseEnum
    description 'Possible two factor authentication methods (availability depends on system configuration)'

    Auth::TwoFactor::Method.descendants.each do |method|
      instance = method.new
      value instance.method_name, instance.method_name(human: true)
    end

  end
end
