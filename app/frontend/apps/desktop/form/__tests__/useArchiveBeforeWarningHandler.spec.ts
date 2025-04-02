// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { type Ref } from 'vue'

import {
  FormHandlerExecution,
  type ChangedField,
  type FormHandlerFunctionData,
  type FormHandlerFunctionReactivity,
  type FormValues,
  type FormSchemaField,
} from '#shared/components/Form/types.ts'

import { useArchiveBeforeWarningHandler } from '../composables/useArchiveBeforeWarningHandler.ts'

import type { FormKitNode } from '@formkit/core'
import type { Except, SetOptional } from 'type-fest'

const getReactivity = (
  changeFields?: Ref<Record<string, Partial<FormSchemaField>>>,
  fields?: Record<
    string,
    {
      show: boolean
      updateFields: boolean
      props: Except<
        SetOptional<FormSchemaField, 'type'>,
        'show' | 'props' | 'updateFields' | 'relation'
      >
    }
  >,
  values?: Record<string, unknown>,
) =>
  ({
    changeFields,
    schemaData: {
      fields: {
        ...fields,
      },
      ...values,
    },
    updateSchemaDataField: () => {},
  }) as unknown as FormHandlerFunctionReactivity

const getData = (changedField?: ChangedField, values?: FormValues) => {
  const mockedSet = vi.fn()
  const mockedRemove = vi.fn()

  return {
    data: {
      formNode: {
        store: {
          set: mockedSet,
          remove: mockedRemove,
        },
        on: vi.fn(),
      } as unknown as FormKitNode,
      changedField,
      values,
      getNodeByName: vi.fn(),
      findNodeByName: vi.fn(),
    } as FormHandlerFunctionData,
    mockedSet,
    mockedRemove,
  }
}

describe('useArchiveBeforeWarningHandler callback', () => {
  it('clears warning when archive_before is missing (initial)', async () => {
    const { callback } = useArchiveBeforeWarningHandler()

    const reactivity = getReactivity(undefined, {
      archive: {
        show: true,
        updateFields: false,
        props: { name: 'archive', value: true },
      },
      archive_before: {
        show: true,
        updateFields: false,
        props: { name: 'archive_before', value: undefined },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(undefined, {
      archive: true,
      archive_before: undefined,
    })

    callback(FormHandlerExecution.InitialSettled, reactivity, data)

    expect(mockedSet).not.toBeCalled()
    expect(mockedRemove).toBeCalledWith('archiveBeforeWarning')
  })

  it('clears warning when archive is turned off (initial)', async () => {
    const { callback } = useArchiveBeforeWarningHandler()

    const dateInFuture = new Date(Date.now() + 1000).toISOString()

    const reactivity = getReactivity(undefined, {
      archive: {
        show: true,
        updateFields: false,
        props: { name: 'archive', value: false },
      },
      archive_before: {
        show: true,
        updateFields: false,
        props: { name: 'archive_before', value: dateInFuture },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(undefined, {
      archive: false,
      archive_before: dateInFuture,
    })

    callback(FormHandlerExecution.InitialSettled, reactivity, data)

    expect(mockedSet).not.toBeCalled()
    expect(mockedRemove).toBeCalledWith('archiveBeforeWarning')
  })

  it('clears warning when archive_before is cleared (change)', async () => {
    const { callback } = useArchiveBeforeWarningHandler()

    const dateInFuture = new Date(Date.now() + 1000).toISOString()

    const reactivity = getReactivity(undefined, {
      archive: {
        show: true,
        updateFields: false,
        props: { name: 'archive', value: true },
      },
      archive_before: {
        show: true,
        updateFields: false,
        props: { name: 'archive_before', value: null },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(
      {
        name: 'archive_before',
        newValue: null,
        oldValue: dateInFuture,
      },
      { archive: false, archive_before: null },
    )

    callback(FormHandlerExecution.FieldChange, reactivity, data)

    expect(mockedSet).not.toBeCalled()
    expect(mockedRemove).toBeCalledWith('archiveBeforeWarning')
  })

  it('clears warning when archive_before is in the past (change)', async () => {
    const { callback } = useArchiveBeforeWarningHandler()

    const dateInPast = new Date(Date.now() - 1000).toISOString()

    const reactivity = getReactivity(undefined, {
      archive: {
        show: true,
        updateFields: false,
        props: {
          name: 'archive',
          value: true,
        },
      },
      archive_before: {
        show: true,
        updateFields: false,
        props: {
          name: 'archive_before',
          value: dateInPast,
        },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(
      {
        name: 'archive_before',
        newValue: dateInPast,
        oldValue: undefined,
      },
      { archive: true, archive_before: dateInPast },
    )

    callback(FormHandlerExecution.FieldChange, reactivity, data)

    expect(mockedSet).not.toBeCalled()
    expect(mockedRemove).toBeCalledWith('archiveBeforeWarning')
  })

  it('sets warning when archive_before is in the future (change)', async () => {
    const { callback } = useArchiveBeforeWarningHandler()

    const dateInFuture = new Date(Date.now() + 1000).toISOString()

    const reactivity = getReactivity(undefined, {
      archive: {
        show: true,
        updateFields: false,
        props: {
          name: 'archive',
          value: true,
        },
      },
      archive_before: {
        show: true,
        updateFields: false,
        props: {
          name: 'archive_before',
          value: dateInFuture,
        },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(
      {
        name: 'archive_before',
        newValue: dateInFuture,
        oldValue: undefined,
      },
      { archive: true, archive_before: dateInFuture },
    )

    callback(FormHandlerExecution.FieldChange, reactivity, data)

    expect(mockedSet).toHaveBeenCalledWith({
      blocking: false,
      key: 'archiveBeforeWarning',
      meta: {},
      type: 'warning',
      value:
        'You have selected a cut-off time in the future. Be aware that all emails (including future ones) are going to be archived until the selected time is reached.',
      visible: true,
    })

    expect(mockedRemove).not.toBeCalled()
  })

  it('does not execute when archive_before is not present', async () => {
    const { callback } = useArchiveBeforeWarningHandler()

    const reactivity = getReactivity(undefined, {
      archive: {
        show: true,
        updateFields: false,
        props: { name: 'archive', value: false },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(undefined, {
      archive: false,
    })

    callback(FormHandlerExecution.InitialSettled, reactivity, data)

    expect(mockedSet).not.toBeCalled()
    expect(mockedRemove).not.toBeCalled()
  })

  it('does not execute when another field is changed', async () => {
    const { callback } = useArchiveBeforeWarningHandler()

    const dateInFuture = new Date(Date.now() + 1000).toISOString()

    const reactivity = getReactivity(undefined, {
      archive: {
        show: true,
        updateFields: false,
        props: {
          name: 'archive',
          value: true,
        },
      },
      archive_before: {
        show: true,
        updateFields: false,
        props: {
          name: 'archive_before',
          value: dateInFuture,
        },
      },
      archive_state_id: {
        show: true,
        updateFields: false,
        props: {
          name: 'archive_state_id',
          value: 4,
        },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(
      {
        name: 'archive_state_id',
        newValue: 4,
        oldValue: undefined,
      },
      { archive: true, archive_before: dateInFuture, archive_state_id: 4 },
    )

    callback(FormHandlerExecution.FieldChange, reactivity, data)

    expect(mockedSet).not.toBeCalled()
    expect(mockedRemove).not.toBeCalled()
  })
})
