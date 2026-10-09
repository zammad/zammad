// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export const SERVICE_WORKER_SCOPE = '/mobile/'

// The service worker is only registered in production builds and in
//   development when it was enabled by hand, so it cannot be awaited.
export const getServiceWorkerRegistration = () =>
  navigator.serviceWorker.getRegistration(SERVICE_WORKER_SCOPE)
