# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class NotificationSoundFileType < BaseEnum
    description 'Available notification sound files'

    value 'Bell',    value: 'Bell.mp3'
    value 'Kalimba', value: 'Kalimba.mp3'
    value 'Marimba', value: 'Marimba.mp3'
    value 'Peep',    value: 'Peep.mp3'
    value 'Plop',    value: 'Plop.mp3'
    value 'Ring',    value: 'Ring.mp3'
    value 'Space',   value: 'Space.mp3'
    value 'Wood',    value: 'Wood.mp3'
    value 'Xylo',    value: 'Xylo.mp3'
  end
end
