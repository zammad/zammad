// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { resetPushNotificationDatabase } from '#tests/support/mock-pushNotificationDatabase.ts'

import {
  forgetAllShownPushNotifications,
  forgetShownPushNotification,
  rememberShownPushNotification,
  takeVanishedPushNotifications,
} from '../shownPushNotifications.ts'

vi.mock('#shared/sw/pushNotificationDatabase.ts', async () => {
  const { pushNotificationDatabaseMock } =
    await import('#tests/support/mock-pushNotificationDatabase.ts')
  return pushNotificationDatabaseMock
})

const shown = (tag: string, path: string, shownAt = Date.now()) => ({ tag, path, shownAt })

const vanishedPaths = async (displayedTags: string[]) =>
  (await takeVanishedPushNotifications(displayedTags)).map((entry) => entry.path)

describe('shownPushNotifications', () => {
  beforeEach(() => {
    resetPushNotificationDatabase()
  })

  it('returns the pushes that left the notification center, latest last', async () => {
    await rememberShownPushNotification(shown('ticket-2', '/tickets/2', Date.now() - 1000))
    await rememberShownPushNotification(shown('ticket-1', '/tickets/1', Date.now() - 2000))
    await rememberShownPushNotification(shown('ticket-3', '/tickets/3'))

    expect(await vanishedPaths(['ticket-3'])).toEqual(['/tickets/1', '/tickets/2'])
  })

  it('returns nothing while every push is still displayed', async () => {
    await rememberShownPushNotification(shown('ticket-1', '/tickets/1'))

    expect(await vanishedPaths(['ticket-1'])).toEqual([])
  })

  it('returns a vanished push only once', async () => {
    await rememberShownPushNotification(shown('ticket-1', '/tickets/1'))

    await takeVanishedPushNotifications([])

    expect(await vanishedPaths([])).toEqual([])
  })

  it('keeps the pushes that are still displayed for later', async () => {
    await rememberShownPushNotification(shown('ticket-1', '/tickets/1'))
    await rememberShownPushNotification(shown('ticket-2', '/tickets/2'))

    await takeVanishedPushNotifications(['ticket-2'])

    expect(await vanishedPaths([])).toEqual(['/tickets/2'])
  })

  it('replaces a push with a newer one of the same tag', async () => {
    await rememberShownPushNotification(
      shown('ticket-1', '/tickets/1#article-1', Date.now() - 1000),
    )
    await rememberShownPushNotification(shown('ticket-1', '/tickets/1#article-2'))

    expect(await vanishedPaths([])).toEqual(['/tickets/1#article-2'])
  })

  it('ignores pushes older than a day', async () => {
    await rememberShownPushNotification(
      shown('ticket-1', '/tickets/1', Date.now() - 25 * 60 * 60 * 1000),
    )

    expect(await vanishedPaths([])).toEqual([])
  })

  it('forgets a push the service worker already handled', async () => {
    await rememberShownPushNotification(shown('ticket-1', '/tickets/1'))

    await forgetShownPushNotification('ticket-1')

    expect(await vanishedPaths([])).toEqual([])
  })

  it('keeps nothing on browsers that report the tap themselves', async () => {
    const userAgent = vi
      .spyOn(navigator, 'userAgent', 'get')
      .mockReturnValue(
        'Mozilla/5.0 (Linux; Android 15) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36',
      )

    await rememberShownPushNotification(shown('ticket-1', '/tickets/1'))

    expect(await vanishedPaths([])).toEqual([])

    userAgent.mockRestore()
  })

  it('forgets every push of the device', async () => {
    await rememberShownPushNotification(shown('ticket-1', '/tickets/1'))

    await forgetAllShownPushNotifications()

    expect(await vanishedPaths([])).toEqual([])
  })
})
