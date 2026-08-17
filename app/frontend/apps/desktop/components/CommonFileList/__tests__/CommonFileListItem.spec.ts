// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { fireEvent } from '@testing-library/vue'

import { getByIconName, queryByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import CommonFileListItem from '../CommonFileListItem.vue'

import type { FileListFile } from '../types.ts'

const touch = vi.hoisted(() => ({ isTouchDevice: false }))

// A real ref, so the template unwraps it — a plain `{ value }` stub would always read
//   as truthy there.
vi.mock('#shared/composables/useTouchDevice.ts', async () => {
  const { computed } = await import('vue')

  return {
    useTouchDevice: () => ({ isTouchDevice: computed(() => touch.isTouchDevice) }),
  }
})

const image: FileListFile = {
  internalId: 1,
  name: 'IMG_1234.png',
  type: 'image/png',
  size: 248_000,
  preview: '/api/attachments/1?preview=1',
  downloadUrl: '/api/attachments/1?disposition=attachment',
}

const calendar: FileListFile = {
  internalId: 2,
  name: 'SomeMeetingFile.ics',
  type: 'text/calendar',
  size: 248_000,
  preview: '/api/attachments/2?preview=1',
  downloadUrl: '/api/attachments/2?disposition=attachment',
}

const table: FileListFile = {
  internalId: 3,
  name: 'SomeTableFile.csv',
  type: 'text/csv',
  size: 248_000,
  preview: '',
  downloadUrl: '/api/attachments/3?disposition=attachment',
}

const renderItem = (file: FileListFile, props: { noRemove?: boolean } = {}) =>
  renderComponent(CommonFileListItem, {
    props: { file, ...props },
    router: true,
    store: true,
  })

describe('CommonFileListItem', () => {
  beforeEach(() => {
    touch.isTouchDevice = false

    mockApplicationConfig({
      api_path: '/api',
      'active_storage.content_types_allowed_inline': ['image/png', 'image/jpeg'],
    })
  })

  describe('previewable files', () => {
    it('renders an image with its thumbnail on the neutral surface', () => {
      const view = renderItem(image)

      const thumbnail = view.getByAltText('Image name: IMG_1234.png')
      expect(thumbnail).toHaveAttribute('src', '/api/attachments/1?preview=1')

      expect(view.getByText('IMG_1234')).toBeInTheDocument()
      expect(view.getByText('.png')).toBeInTheDocument()
      expect(view.getByText('242 KB')).toBeInTheDocument()

      expect(view.getByTestId('file-list-item')).toHaveClass('bg-neutral-50', 'dark:bg-gray-500')
    })

    it('emits preview with the image type', async () => {
      const view = renderItem(image)

      await view.events.click(view.getByRole('button', { name: 'Preview IMG_1234.png' }))

      expect(view.emitted().preview).toEqual([['image']])
    })

    it('emits preview with the calendar type', async () => {
      const view = renderItem(calendar)

      const button = view.getByRole('button', { name: 'Preview SomeMeetingFile.ics' })

      // No thumbnail for a calendar file — it shows its content-type icon instead
      //   (`calendar` is aliased to `file-calendar` on desktop).
      expect(view.queryByAltText('Image of SomeMeetingFile.ics')).not.toBeInTheDocument()
      expect(getByIconName(button, 'file-calendar')).toBeInTheDocument()

      await view.events.click(button)

      expect(view.emitted().preview).toEqual([['calendar']])
    })

    it('falls back to the content-type icon and drops the surface when the thumbnail fails', async () => {
      const view = renderItem(image)

      await fireEvent.error(view.getByAltText('Image name: IMG_1234.png'))

      expect(view.queryByAltText('Image name: IMG_1234.png')).not.toBeInTheDocument()
      expect(getByIconName(view.getByTestId('file-list-item'), 'file-image')).toBeInTheDocument()
      expect(view.getByTestId('file-list-item')).not.toHaveClass('bg-neutral-50')
    })
  })

  describe('files without a preview', () => {
    it('renders the size of a zero-byte file', () => {
      const view = renderItem({ ...table, size: 0 })

      expect(view.getByText('0 Bytes')).toBeInTheDocument()
    })

    it('renders the row as a download link without the neutral surface', () => {
      const view = renderItem(table)

      expect(view.getByTestId('file-list-item')).not.toHaveClass('bg-neutral-50')
      expect(view.queryByRole('button', { name: /^Preview/ })).not.toBeInTheDocument()

      // Only one link is announced: the redundant download icon is aria-hidden here.
      const row = view.getByRole('link', { name: 'Download SomeTableFile.csv' })
      expect(row).toHaveAttribute('href', '/api/attachments/3?disposition=attachment')
      expect(row).toHaveAttribute('download', 'SomeTableFile.csv')
    })

    it('opens a file that cannot be downloaded in a new tab', () => {
      const view = renderItem({ ...table, name: 'page.html', type: 'text/html' })

      const row = view.getByRole('link', { name: 'Open page.html' })
      expect(row).toHaveAttribute('target', '_blank')
      expect(row).not.toHaveAttribute('download')
    })
  })

  describe('actions', () => {
    it('offers a download link next to the file', () => {
      const view = renderItem(image)

      const download = view.getByRole('link', { name: 'Download file: IMG_1234.png' })
      expect(download).toHaveAttribute('href', '/api/attachments/1?disposition=attachment')
      expect(download).toHaveAttribute('download', 'IMG_1234.png')
      expect(getByIconName(download, 'download')).toBeInTheDocument()
    })

    it('emits remove when the remove button is used', async () => {
      const view = renderItem(image)

      await view.events.click(view.getByRole('button', { name: 'Remove file: IMG_1234.png' }))

      expect(view.emitted().remove).toBeTruthy()
    })

    it('hides the remove button with no-remove', () => {
      const view = renderItem(image, { noRemove: true })

      expect(
        view.queryByRole('button', { name: 'Remove file: IMG_1234.png' }),
      ).not.toBeInTheDocument()
      expect(queryByIconName(view.getByTestId('file-list-item'), 'x-lg')).not.toBeInTheDocument()
    })

    it('reveals the actions on hover only on a pointer device', () => {
      const view = renderItem(image)

      expect(view.getByTestId('file-list-item-actions')).toHaveClass('opacity-0')
    })

    it('keeps the actions visible on a touch device', () => {
      touch.isTouchDevice = true

      const view = renderItem(image)

      expect(view.getByTestId('file-list-item-actions')).not.toHaveClass('opacity-0')
    })
  })
})
