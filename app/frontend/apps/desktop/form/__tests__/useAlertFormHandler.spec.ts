// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { type Ref } from 'vue'

import {
  FormHandlerExecution,
  type ChangedField,
  type FormHandlerFunctionData,
  type FormHandlerFunctionReactivity,
  type FormValues,
  type FormSchemaField,
  type ReactiveFormSchemaDataField,
} from '#shared/components/Form/types.ts'

import { useAlertFormHandler } from '../composables/useAlertFormHandler.ts'

import type { FormKitNode } from '@formkit/core'

const getReactivity = (
  changeFields?: Ref<Record<string, Partial<FormSchemaField>>>,
  fields?: Record<string, Partial<ReactiveFormSchemaDataField>>,
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

const key = 'fieldNameWarning'
const message = { key }
const eventHandler = vi.fn()

describe('useAlertFormHandler callback', () => {
  it('clears warning when callback returns false (initial)', async () => {
    const { callback } = useAlertFormHandler(
      'fieldName',
      message,
      () => false, // initialAddCallback
      () => false,
      eventHandler,
    )

    const reactivity = getReactivity(undefined, {
      fieldName: {
        show: true,
        updateFields: false,
        props: { name: 'fieldName', value: undefined },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(undefined, {
      fieldName: undefined,
    })

    callback(FormHandlerExecution.InitialSettled, reactivity, data)

    expect(mockedSet).not.toBeCalled()
    expect(mockedRemove).toBeCalledWith(key)
  })

  it('adds warning when callback returns true (initial)', async () => {
    const { callback } = useAlertFormHandler(
      'fieldName',
      message,
      () => true, // initialAddCallback
      () => false,
      eventHandler,
    )

    const reactivity = getReactivity(undefined, {
      fieldName: {
        show: true,
        updateFields: false,
        props: { name: 'fieldName', value: undefined },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(undefined, {
      fieldName: undefined,
    })

    callback(FormHandlerExecution.InitialSettled, reactivity, data)

    expect(mockedSet).not.toBeCalledWith({
      blocking: false,
      key,
      type: 'warning',
      visible: true,
    })

    expect(mockedRemove).not.toBeCalled()
  })

  it('clears warning when callback returns false (change)', async () => {
    const { callback } = useAlertFormHandler(
      'fieldName',
      message,
      () => false,
      () => false, // changeAddCallback
      eventHandler,
    )

    const reactivity = getReactivity(undefined, {
      fieldName: {
        show: true,
        updateFields: false,
        props: { name: 'fieldName', value: undefined },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(
      {
        name: 'fieldName',
        newValue: 'foobar',
        oldValue: undefined,
      },
      { fieldName: undefined },
    )

    callback(FormHandlerExecution.FieldChange, reactivity, data)

    expect(mockedSet).not.toBeCalled()
    expect(mockedRemove).toBeCalledWith(key)
  })

  it('adds warning when callback returns true (change)', async () => {
    const { callback } = useAlertFormHandler(
      'fieldName',
      message,
      () => false,
      () => true, // changeAddCallback
      eventHandler,
    )

    const reactivity = getReactivity(undefined, {
      fieldName: {
        show: true,
        updateFields: false,
        props: { name: 'fieldName', value: undefined },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(
      {
        name: 'fieldName',
        newValue: 'foobar',
        oldValue: undefined,
      },
      { fieldName: undefined },
    )

    callback(FormHandlerExecution.FieldChange, reactivity, data)

    expect(mockedSet).not.toBeCalledWith({
      blocking: false,
      key,
      type: 'warning',
      visible: true,
    })

    expect(mockedRemove).not.toBeCalled()
  })

  it('does not execute when another field is changed', async () => {
    const { callback } = useAlertFormHandler(
      'fieldName',
      message,
      () => false,
      () => false,
      eventHandler,
    )

    const reactivity = getReactivity(undefined, {
      fieldName: {
        show: true,
        updateFields: false,
        props: {
          name: 'fieldName',
          value: undefined,
        },
      },
      anotherField: {
        show: true,
        updateFields: false,
        props: {
          name: 'anotherField',
          value: undefined,
        },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(
      {
        name: 'anotherField',
        newValue: 'foobar',
        oldValue: undefined,
      },
      { fieldName: undefined, anotherField: 'foobar' },
    )

    callback(FormHandlerExecution.FieldChange, reactivity, data)

    expect(mockedSet).not.toBeCalled()
    expect(mockedRemove).not.toBeCalled()
  })
})
