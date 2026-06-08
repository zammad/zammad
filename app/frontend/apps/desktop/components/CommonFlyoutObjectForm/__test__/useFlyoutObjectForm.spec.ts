// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { beforeEach, describe, expect, it, vi } from 'vitest'

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { useFlyoutObjectForm } from '../useFlyoutObjectForm.ts'

import type { ObjectDescription } from '../types.ts'

const mockFlyoutOpen = vi.fn().mockResolvedValue(undefined)

vi.mock('#desktop/components/CommonFlyout/useFlyout.ts', () => ({
  useFlyout: vi.fn(() => ({
    open: mockFlyoutOpen,
  })),
}))

describe('useFlyoutObjectForm', () => {
  beforeEach(() => {
    mockFlyoutOpen.mockReset()
  })

  it('returns openFlyoutObjectForm function', () => {
    const { openFlyoutObjectForm } = useFlyoutObjectForm('test-form', EnumObjectManagerObjects.User)

    expect(openFlyoutObjectForm).toBeDefined()

    expect(typeof openFlyoutObjectForm).toBe('function')
  })

  it('opens flyout with correct props when openFlyoutObjectForm is called', async () => {
    const formName = 'user-form'
    const formType = EnumObjectManagerObjects.User

    const { openFlyoutObjectForm } = useFlyoutObjectForm(formName, formType)

    const objectProps: Partial<ObjectDescription> = {
      object: { id: '123' },
      title: 'Edit User',
    }

    await openFlyoutObjectForm(objectProps as ObjectDescription)

    expect(mockFlyoutOpen).toHaveBeenCalledWith({
      name: formName,
      type: formType,
      ...objectProps,
    })
  })

  it('merges props correctly with name and type', async () => {
    const formName = 'organization-form'
    const formType = EnumObjectManagerObjects.Organization

    const { openFlyoutObjectForm } = useFlyoutObjectForm(formName, formType)

    const objectProps: Partial<ObjectDescription> = {
      object: { id: '456' },
      title: 'Create Organization',
      onSuccess: vi.fn(),
      onError: vi.fn(),
    }

    await openFlyoutObjectForm(objectProps as ObjectDescription)

    expect(mockFlyoutOpen).toHaveBeenCalledWith({
      name: formName,
      type: formType,
      object: { id: '456' },
      title: 'Create Organization',
      onSuccess: objectProps.onSuccess,
      onError: objectProps.onError,
    })
  })

  it('handles callbacks in object props', async () => {
    const { openFlyoutObjectForm } = useFlyoutObjectForm(
      'ticket-form',
      EnumObjectManagerObjects.Ticket,
    )

    const onSuccess = vi.fn()
    const onError = vi.fn()
    const onChangedField = vi.fn()

    await openFlyoutObjectForm({
      onSuccess,
      onError,
      onChangedField,
    } as unknown as ObjectDescription)

    expect(mockFlyoutOpen).toHaveBeenCalledWith({
      name: 'ticket-form',
      type: EnumObjectManagerObjects.Ticket,
      onSuccess,
      onError,
      onChangedField,
    })
  })

  it.each([
    { type: EnumObjectManagerObjects.User, name: 'user-form' },
    { type: EnumObjectManagerObjects.Organization, name: 'org-form' },
    { type: EnumObjectManagerObjects.Ticket, name: 'ticket-form' },
  ])('works with $type object manager type', async ({ type, name }) => {
    mockFlyoutOpen.mockReset().mockResolvedValue(undefined)

    const { openFlyoutObjectForm } = useFlyoutObjectForm(name, type)

    await openFlyoutObjectForm({ object: { id: 'test-id' } } as unknown as ObjectDescription)

    expect(mockFlyoutOpen).toHaveBeenCalledWith({
      name,
      type,
      object: { id: 'test-id' },
    })
  })

  it('returns the result from flyout.open', async () => {
    const { openFlyoutObjectForm } = useFlyoutObjectForm('test-form', EnumObjectManagerObjects.User)

    const result = await openFlyoutObjectForm({
      object: { id: '123' },
    } as unknown as ObjectDescription)

    expect(result).toBeUndefined()
    expect(mockFlyoutOpen).toHaveBeenCalledWith({
      name: 'test-form',
      type: EnumObjectManagerObjects.User,
      object: { id: '123' },
    })
  })
})
