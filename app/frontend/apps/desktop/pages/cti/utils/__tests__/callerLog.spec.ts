// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { commentOnlyMatch, knownMatch } from '../../__tests__/mocks/caller-log-mocks.ts'
import {
  formatDuration,
  getCallerLogMatchName,
  getCallerLogNamedMatches,
  getCallerLogStatus,
  getCallerLogStatusDisplay,
  isCallerLogDoneDisabled,
} from '../callerLog.ts'

describe('getCallerLogStatus', () => {
  it.each([
    ['newCall', null, 'Ringing…'],
    ['answer', null, 'Connected'],
    ['hangup', 'cancel', 'Not reached'],
    ['hangup', 'noAnswer', 'Not reached'],
    ['hangup', 'congestion', 'Not reached'],
    ['hangup', 'busy', 'Busy'],
    ['hangup', 'voicemail', 'Voicemail'],
    ['hangup', 'notFound', 'Does not exist'],
    ['hangup', 'normalClearing', 'Call ended'],
    ['hangup', 'somethingElse', 'somethingElse'],
    ['hangup', null, ''],
    ['unknownState', null, 'unknownState'],
    ['unknownState', 'reason', 'unknownState, reason'],
  ])('maps state %s with comment %s to "%s"', (state, comment, expected) => {
    expect(getCallerLogStatus({ state, comment })).toBe(expected)
  })
})

describe('getCallerLogStatusDisplay', () => {
  const muted = {
    iconClass: 'text-stone-200 dark:text-neutral-500',
    labelClass: 'text-gray-100 dark:text-neutral-400',
  }

  // A call in progress keeps its own icon color, the label stays muted like every other status.
  const connected = {
    iconClass: 'text-green-400',
    labelClass: 'text-gray-100 dark:text-neutral-400',
  }

  const ringing = {
    iconClass: 'text-yellow-500 animate-vibrate motion-reduce:animate-none',
    labelClass: 'text-black! dark:text-white!',
  }

  it.each([
    ['newCall', null, 'in', 'telephone-inbound', ringing],
    ['newCall', null, 'out', 'telephone-outbound', ringing],
    ['answer', null, 'in', 'telephone-v', connected],
    // The same icon as a call in progress, but the call is over, so it is muted again.
    ['hangup', 'normalClearing', 'in', 'telephone-v', muted],
    ['hangup', 'cancel', 'in', 'telephone', muted],
    ['hangup', 'noAnswer', 'in', 'telephone', muted],
    ['hangup', 'congestion', 'in', 'telephone', muted],
    ['hangup', 'busy', 'in', 'telephone-x', muted],
    ['hangup', 'voicemail', 'in', 'mic', muted],
    ['hangup', 'notFound', 'out', 'x', muted],
  ])(
    'maps state %s with comment %s of a %s call to %s',
    (state, comment, direction, icon, colors) => {
      expect(getCallerLogStatusDisplay({ state, comment, direction })).toEqual({
        icon,
        ...colors,
      })
    },
  )

  it.each([
    ['a hangup without a comment', { state: 'hangup', comment: null }],
    ['an unknown comment', { state: 'hangup', comment: 'somethingElse' }],
    ['an unknown state', { state: 'unknownState', comment: null }],
  ])('falls back to the generic icon for %s', (_, { state, comment }) => {
    expect(getCallerLogStatusDisplay({ state, comment, direction: 'in' })).toEqual({
      icon: 'phone',
      ...muted,
    })
  })
})

describe('isCallerLogDoneDisabled', () => {
  const now = new Date('2026-09-21T09:01:00Z')

  const secondsBefore = (seconds: number) => new Date(now.getTime() - seconds * 1000).toISOString()

  it.each([
    ['a ringing call from this minute', 'newCall', 30, true],
    ['a connected call from this minute', 'answer', 60, true],
    ['a ringing call older than a minute', 'newCall', 61, false],
    ['a finished call from this minute', 'hangup', 5, false],
  ])('%s: %s', (_, state, seconds, expected) => {
    expect(isCallerLogDoneDisabled({ state, createdAt: secondsBefore(seconds) }, now)).toBe(
      expected,
    )
  })
})

describe('formatDuration', () => {
  it.each([
    [0, '00:00'],
    [5, '00:05'],
    [65, '01:05'],
    [3599, '59:59'],
    [3600, '1:00:00'],
    [3725, '1:02:05'],
  ])('formats %s seconds as %s', (seconds, expected) => {
    expect(formatDuration(seconds)).toBe(expected)
  })

  it('returns an empty string without a value', () => {
    expect(formatDuration(null)).toBe('')
    expect(formatDuration(undefined)).toBe('')
  })
})

describe('getCallerLogMatchName', () => {
  it('prefers the full name of the matched user', () => {
    expect(getCallerLogMatchName(knownMatch, 'last_first_comma')).toBe('Franz Bauer')
  })

  // A role with cti.agent only gets the name fields without the composed full name.
  it('composes the name from the name fields when the full name is missing', () => {
    const match = { ...knownMatch, user: { ...knownMatch.user!, fullname: null } }

    expect(getCallerLogMatchName(match, 'first_last')).toBe('Franz Bauer')
    expect(getCallerLogNamedMatches([match], 'first_last')).toEqual([match])
  })

  it('composes the name in the given format', () => {
    const match = { ...knownMatch, user: { ...knownMatch.user!, fullname: null } }

    expect(getCallerLogMatchName(match, 'last_first_comma')).toBe('Bauer, Franz')
  })

  it('leaves out an empty name field', () => {
    const match = { ...knownMatch, user: { ...knownMatch.user!, fullname: null, firstname: '' } }

    expect(getCallerLogMatchName(match, 'first_last')).toBe('Bauer')
  })

  it('falls back to the comment without a user', () => {
    expect(getCallerLogMatchName(commentOnlyMatch, 'first_last')).toBe('Carla Weber')
  })

  it('falls back to the comment when the user has no name at all', () => {
    const match = {
      ...knownMatch,
      comment: 'Franz B.',
      user: { ...knownMatch.user!, fullname: null, firstname: null, lastname: null },
    }

    expect(getCallerLogMatchName(match, 'first_last')).toBe('Franz B.')
  })
})
