// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// Lets the app find out which push was tapped to bring it back to the front.
//
// iOS sends no `notificationclick` to an installed app that was started from
//   its home screen icon and runs in the background, a tap only brings the app
//   back. The service worker woken for a push cannot reach the app either, it
//   never sees the app window. So the worker writes down every push it shows,
//   and the app looks for one that left the notification center when it comes
//   back. Other platforms report the tap, so this is done on Apple's WebKit only.

import { isAppleWebKit } from '#shared/utils/webPush.ts'

import {
  deleteDatabase,
  deleteEntries,
  isDatabaseAvailable,
  putEntry,
  readEntries,
  type ShownPushNotification,
} from './pushNotificationDatabase.ts'

export type { ShownPushNotification }

// Same lifetime as a push message at the push service.
const MAX_AGE_MS = 24 * 60 * 60 * 1000

const isNeeded = () => isDatabaseAvailable() && isAppleWebKit()

// A newer push with the same tag replaces the older one on the device, too,
//   so it replaces the entry of the same tag here.
export const rememberShownPushNotification = async (entry: ShownPushNotification) => {
  if (!isNeeded()) return

  await putEntry(entry)

  const oldest = Date.now() - MAX_AGE_MS
  const expired = (await readEntries()).filter((existing) => existing.shownAt < oldest)

  if (expired.length) await deleteEntries(expired.map((existing) => existing.tag))
}

// Where the platform reports a click or a dismissal, the push needs no guessing.
export const forgetShownPushNotification = async (tag: string) => {
  if (!isNeeded()) return

  await deleteEntries([tag])
}

// Leaves no database behind once push is off for this device.
export const forgetAllShownPushNotifications = async () => {
  if (!isNeeded()) return

  await deleteDatabase()
}

// Takes the remembered pushes that are no longer displayed, latest last.
//   A tap removes the tapped push, deleting removes it as well.
export const takeVanishedPushNotifications = async (displayedTags: string[]) => {
  if (!isNeeded()) return []

  const oldest = Date.now() - MAX_AGE_MS
  const vanished = (await readEntries()).filter(
    (entry) => entry.shownAt >= oldest && !displayedTags.includes(entry.tag),
  )
  if (!vanished.length) return []

  await deleteEntries(vanished.map((entry) => entry.tag))

  return vanished.sort((first, second) => first.shownAt - second.shownAt)
}
