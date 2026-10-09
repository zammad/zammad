// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export const isPushSupported = () =>
  typeof window !== 'undefined' &&
  'Notification' in window &&
  'serviceWorker' in navigator &&
  'PushManager' in window

// applicationServerKey has to be the raw key bytes, the setting holds it base64url encoded.
export const urlBase64ToUint8Array = (base64String: string) => {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4)
  const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/')

  return Uint8Array.from(window.atob(base64), (char) => char.charCodeAt(0))
}

// An iPhone or iPad, where push needs the app on the home screen. iPadOS
//   reports itself as a Mac, a touch screen tells the two apart.
export const isAppleMobileDevice = () =>
  /iPhone|iPad|iPod/.test(navigator.userAgent) ||
  (/Macintosh/.test(navigator.userAgent) && navigator.maxTouchPoints > 1)

// Safari on any Apple device. A service worker has no touch points to tell an
//   iPad from a Mac, so this covers every Safari. Other browsers on iOS cannot
//   receive web push.
export const isAppleWebKit = (userAgent = navigator.userAgent) =>
  /AppleWebKit/.test(userAgent) &&
  !/Chrome|Chromium|CriOS|Edg|Firefox|FxiOS|Android/.test(userAgent)
