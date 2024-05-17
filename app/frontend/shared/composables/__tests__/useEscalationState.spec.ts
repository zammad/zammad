// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { toRef, type ToRef } from 'vue'

import { EscalationState, useEscalationState } from '../useEscalationState.ts'

const getState = (value: ToRef<string | undefined | null>) => {
  return useEscalationState(value).value
}

describe('correctly returns the escalation state', () => {
  it('returns no state if undefined', () => {
    expect(getState(toRef(() => undefined))).toBe(EscalationState.None)
  })

  it('returns no state if incorrect date', () => {
    expect(getState(toRef(() => 't01.01.2012t'))).toBe(EscalationState.None)
  })

  it('returns warning if date is in the future', () => {
    expect(getState(toRef(() => new Date(2090, 1, 1).toISOString()))).toBe(
      EscalationState.Warning,
    )
  })

  it('returns escalated if date is in the past', () => {
    expect(getState(toRef(() => new Date(2000, 1, 1).toISOString()))).toBe(
      EscalationState.Escalated,
    )
  })

  it('reactively updates the value', async () => {
    const now = new Date()
    const nextSecond = new Date(now.getTime() + 1000).toISOString()
    const state = useEscalationState(toRef(() => nextSecond))
    expect(state.value).toBe(EscalationState.Warning)
    await vi.waitFor(() => {
      expect(state.value).toBe(EscalationState.Escalated)
    }, 10_000)
  }, 10_000)
})
