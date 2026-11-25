// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { type Ref, nextTick } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { useKeyboardShortcut } from '#shared/composables/useKeyboardShortcut/useKeyboardShortcut.ts'
import { connected } from '#shared/server/connection.ts'

import ConnectionLostDialog from '../ConnectionLostDialog.vue'

const closeDialogMock = vi.hoisted(() => vi.fn())

vi.mock('#desktop/components/CommonDialog/useDialog.ts', async (originalModule) => {
  const module =
    await originalModule<typeof import('#desktop/components/CommonDialog/useDialog.ts')>()

  return {
    ...module,
    closeDialog: closeDialogMock,
  }
})

vi.mock('#shared/server/connection.ts', async (originalModule) => {
  const module = await originalModule<typeof import('#shared/server/connection.ts')>()
  const { ref } = await import('vue')

  return {
    ...module,
    connected: ref(false),
  }
})

const setConnected = async (value: boolean) => {
  ;(connected as unknown as Ref<boolean>).value = value
  await nextTick()
}

const KONAMI_CODE =
  '{ArrowUp}{ArrowUp}{ArrowDown}{ArrowDown}{ArrowLeft}{ArrowRight}{ArrowLeft}{ArrowRight}ba'

describe('ConnectionLostDialog', () => {
  beforeEach(async () => {
    await setConnected(false)
  })

  it('renders the connection lost dialog', () => {
    const wrapper = renderComponent(ConnectionLostDialog, { router: true, dialog: true })

    expect(wrapper.getByRole('dialog')).toBeInTheDocument()
    expect(
      wrapper.getByRole('heading', { level: 3, name: 'Lost network connection' }),
    ).toBeInTheDocument()
    expect(wrapper.getByText('Trying to reconnect…')).toBeInTheDocument()
    expect(wrapper.getByIconName('wifi-off')).toBeInTheDocument()
    expect(wrapper.queryByTestId('connection-lost-game')).not.toBeInTheDocument()
  })

  it('reveals the game after the Konami code', async () => {
    const wrapper = renderComponent(ConnectionLostDialog, { router: true, dialog: true })

    await wrapper.events.keyboard(`{ArrowUp}${KONAMI_CODE}`)

    expect(wrapper.getByTestId('connection-lost-game')).toBeInTheDocument()
    expect(wrapper.getByRole('status')).toHaveTextContent(
      'Press the up or down arrow key to start.',
    )
    expect(wrapper.getByText('Score: 0')).toBeInTheDocument()
  })

  it('ignores a lone modifier press within the sequence', async () => {
    const wrapper = renderComponent(ConnectionLostDialog, { router: true, dialog: true })

    await wrapper.events.keyboard(KONAMI_CODE.replace('ba', '{Shift}ba'))

    expect(wrapper.getByTestId('connection-lost-game')).toBeInTheDocument()
  })

  it('accepts the letters by their physical key on a non-Latin layout', async () => {
    const wrapper = renderComponent(ConnectionLostDialog, { router: true, dialog: true })

    await wrapper.events.keyboard(
      '{ArrowUp}{ArrowUp}{ArrowDown}{ArrowDown}{ArrowLeft}{ArrowRight}{ArrowLeft}{ArrowRight}',
    )
    // A Russian layout types these letters on the B and A keys.
    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'и', code: 'KeyB' }))
    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'ф', code: 'KeyA' }))

    expect(await wrapper.findByTestId('connection-lost-game')).toBeInTheDocument()
  })

  it('keeps the keys of the sequence from the shortcuts behind the dialog', async () => {
    mockPermissions(['ticket.agent'])

    const shortcutHandler = vi.fn()

    const wrapper = renderComponent(
      {
        components: { ConnectionLostDialog },
        template: '<ConnectionLostDialog />',
        setup: () => {
          useKeyboardShortcut('notifications', () => shortcutHandler('notifications'))
          useKeyboardShortcut('navigate-articles', () => shortcutHandler('navigate-articles'))
          useKeyboardShortcut('open-note-box', () => shortcutHandler('open-note-box'))
        },
      },
      { router: true, dialog: true, store: true },
    )

    await wrapper.events.keyboard(`${KONAMI_CODE}x`)

    expect(wrapper.getByTestId('connection-lost-game')).toBeInTheDocument()
    expect(shortcutHandler).toHaveBeenCalledOnce()
    expect(shortcutHandler).toHaveBeenCalledWith('open-note-box')
  })

  it('leaves the text typed into a field behind the dialog alone', async () => {
    const wrapper = renderComponent(
      {
        components: { ConnectionLostDialog },
        template: '<input aria-label="Reply" /><ConnectionLostDialog />',
      },
      { router: true, dialog: true },
    )

    const input = wrapper.getByRole('textbox', { name: 'Reply' })

    input.focus()
    await wrapper.events.keyboard('thanks a bunch')

    expect(input).toHaveValue('thanks a bunch')
  })

  it('keeps the game hidden for an incomplete sequence', async () => {
    const wrapper = renderComponent(ConnectionLostDialog, { router: true, dialog: true })

    await wrapper.events.keyboard(KONAMI_CODE.replace('{ArrowLeft}', '{ArrowRight}'))

    expect(wrapper.queryByTestId('connection-lost-game')).not.toBeInTheDocument()
  })

  it('starts the game with an arrow key', async () => {
    const wrapper = renderComponent(ConnectionLostDialog, { router: true, dialog: true })

    await wrapper.events.keyboard(KONAMI_CODE)
    await wrapper.events.keyboard('{ArrowDown}')

    expect(wrapper.getByRole('status')).toBeEmptyDOMElement()
  })

  it('ignores space in the game', async () => {
    const wrapper = renderComponent(ConnectionLostDialog, { router: true, dialog: true })

    await wrapper.events.keyboard(KONAMI_CODE)
    await wrapper.events.keyboard('[Space]')

    expect(wrapper.getByRole('status')).toHaveTextContent(
      'Press the up or down arrow key to start.',
    )
  })

  describe('when the connection is restored', () => {
    it('closes itself', async () => {
      renderComponent(ConnectionLostDialog, { router: true, dialog: true })

      await setConnected(true)

      expect(closeDialogMock).toHaveBeenCalledWith('connection-lost', true)
    })

    it('closes itself when it is mounted after the connection came back', async () => {
      await setConnected(true)

      renderComponent(ConnectionLostDialog, { router: true, dialog: true })

      expect(closeDialogMock).toHaveBeenCalledWith('connection-lost', true)
    })

    it('stays open for the game and lets the player close it', async () => {
      const wrapper = renderComponent(ConnectionLostDialog, { router: true, dialog: true })

      expect(wrapper.queryByRole('button', { name: 'Close dialog' })).not.toBeInTheDocument()

      await wrapper.events.keyboard(KONAMI_CODE)
      await setConnected(true)

      expect(closeDialogMock).not.toHaveBeenCalled()
      expect(
        wrapper.getByRole('heading', { level: 3, name: 'Network connection restored' }),
      ).toBeInTheDocument()
      expect(
        wrapper.getByText('You can close this dialog and get back to work.'),
      ).toBeInTheDocument()
      expect(wrapper.getByIconName('check-circle-outline')).toBeInTheDocument()
      expect(wrapper.getByTestId('connection-lost-game')).toBeInTheDocument()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Close dialog' }))

      expect(closeDialogMock).toHaveBeenCalledWith('connection-lost', true)
    })

    it('goes back to reconnecting when the connection is lost again', async () => {
      const wrapper = renderComponent(ConnectionLostDialog, { router: true, dialog: true })

      await wrapper.events.keyboard(KONAMI_CODE)
      await setConnected(true)
      await setConnected(false)

      expect(
        wrapper.getByRole('heading', { level: 3, name: 'Lost network connection' }),
      ).toBeInTheDocument()
      expect(wrapper.getByText('Trying to reconnect…')).toBeInTheDocument()
      expect(wrapper.queryByRole('button', { name: 'Close dialog' })).not.toBeInTheDocument()
      expect(wrapper.getByTestId('connection-lost-game')).toBeInTheDocument()
    })
  })
})
