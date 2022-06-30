// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { getDialogMeta } from '@shared/composables/useDialog'
import { renderComponent } from '@tests/support/components'
import CommonDialog from '../CommonDialog.vue'

describe('visuals for common dialog', () => {
  beforeEach(() => {
    const { dialogsOptions } = getDialogMeta()
    dialogsOptions.set('dialog', {
      name: 'dialog',
      component: vi.fn(),
    })
  })

  it('rendering with label and content', () => {
    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
        label: 'Some Label',
      },
      slots: {
        default: 'Content Slot',
      },
    })

    expect(view.getByText('Some Label')).toBeInTheDocument()
    expect(view.getByText('Content Slot')).toBeInTheDocument()
    expect(view.getByText('Done')).toBeInTheDocument()
  })

  it('can render label as slot', () => {
    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
      },
      slots: {
        label: 'Some Label',
      },
    })

    expect(view.getByText('Some Label')).toBeInTheDocument()
  })

  it('can close dialog with keyboard and clicks', async () => {
    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
      },
    })

    await view.events.keyboard('{Escape}')

    const emitted = view.emitted()

    expect(emitted.close).toHaveLength(1)

    await view.events.click(view.getByRole('button', { name: /Done/ }))

    expect(emitted.close).toHaveLength(2)
  })

  // TODO closing with pulling down is tested inside e2e
})
