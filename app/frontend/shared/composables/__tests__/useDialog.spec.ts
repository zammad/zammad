// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises, mount } from '@vue/test-utils'
import {
  destroyComponent,
  pushComponent,
} from '@shared/components/DynamicInitializer/manage'
import { getDialogMeta, useDialog } from '../useDialog'

vi.mock('@shared/components/DynamicInitializer/manage', () => {
  return {
    destroyComponent: vi.fn(),
    pushComponent: vi.fn(),
  }
})

const inContext = (fn: () => void) => {
  const component = {
    setup() {
      fn()
      return () => null
    },
  }
  return mount(component)
}

describe('use dialog usage', () => {
  beforeEach(() => {
    const { dialogsOptions } = getDialogMeta()
    dialogsOptions.clear()
  })

  test('name and component are required', () => {
    // @ts-expect-error - component is required
    useDialog({ name: 'name' })
    // @ts-expect-error - name is required
    useDialog({
      component: vi.fn(),
    })
    useDialog({
      name: 'name',
      component: vi.fn(),
    })
  })

  test('adds and removes meta data', async () => {
    const vm = inContext(() => {
      useDialog({
        name: 'name',
        component: vi.fn(),
      })
    })
    const { dialogsOptions } = getDialogMeta()

    expect(dialogsOptions.size).toBe(1)
    expect(dialogsOptions.has('name')).toBe(true)

    vm.unmount()

    await flushPromises()

    expect(dialogsOptions.size).toBe(0)
    expect(dialogsOptions.has('name')).toBe(false)
  })

  test('opens and closes dialog', async () => {
    const component = vi.fn().mockResolvedValue({})
    const dialog = useDialog({
      name: 'name',
      component,
    })
    await dialog.open()

    const { dialogsOpened } = getDialogMeta()

    expect(dialog.isOpened.value).toBe(true)
    expect(component).toHaveBeenCalled()
    expect(dialogsOpened.value.has('name')).toBe(true)
    expect(pushComponent).toHaveBeenCalledWith(
      'dialog',
      'name',
      expect.anything(),
      {},
    )

    await dialog.close()

    expect(dialog.isOpened.value).toBe(false)
    expect(dialogsOpened.value.has('name')).toBe(false)
    expect(destroyComponent).toHaveBeenCalledWith('dialog', 'name')
  })

  test('prefetch starts loading', async () => {
    const component = vi.fn().mockResolvedValue({})
    const dialog = useDialog({
      name: 'name',
      component,
    })
    await dialog.prefetch()
    expect(component).toHaveBeenCalled()
  })

  test('hooks are called', async () => {
    const component = vi.fn().mockResolvedValue({})
    const beforeOpen = vi.fn()
    const afterClose = vi.fn()

    const dialog = useDialog({
      name: 'name',
      component,
      beforeOpen,
      afterClose,
    })
    await dialog.open()

    expect(beforeOpen).toHaveBeenCalled()
    expect(afterClose).not.toHaveBeenCalled()

    await dialog.close()

    expect(afterClose).toHaveBeenCalled()
  })
})
