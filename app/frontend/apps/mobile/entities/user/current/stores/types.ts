// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export type PushNotificationState =
  | 'hidden'
  | 'unavailable'
  | 'denied'
  | 'expired'
  | 'disabled'
  | 'enabled'

// What keeps push from working on this device, in the order it has to be fixed.
export type PushNotificationUnavailableReason =
  | 'insecure-connection'
  | 'not-installed'
  | 'unsupported-browser'
  | 'not-configured'
  | 'service-worker-missing'
  | 'service-worker-installing'
  | 'push-service-rejected'
