// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import buildIconsQueries from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { imageViewerOptions } from '#shared/composables/useImageViewer.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import CommonImageViewer from '../CommonImageViewer.vue'

const images = [
  { src: 'https://localhost/first.png', title: 'first.png' },
  { src: 'https://localhost/second.png', title: 'second.png' },
  { src: 'https://localhost/third.png', title: 'third.png' },
]

describe('CommonImageViewer', () => {
  afterEach(() => {
    imageViewerOptions.value = { visible: false, index: 0, images: [] }
  })

  it('renders the current image with the image actions toolbar', async () => {
    const wrapper = renderComponent(CommonImageViewer)

    expect(wrapper.getByTestId('imageViewer')).toBeEmptyDOMElement()

    imageViewerOptions.value = {
      visible: true,
      index: 0,
      images: [{ src: 'https://localhost/image.png', title: 'image.png' }],
    }

    expect(await wrapper.findByRole('toolbar', { name: 'Image actions' })).toBeVisible()
    expect(wrapper.getByRole('button', { name: 'Zoom in' })).toBeVisible()
  })

  it('hides the viewer again on the hide event', async () => {
    const wrapper = renderComponent(CommonImageViewer)

    imageViewerOptions.value = {
      visible: true,
      index: 0,
      images: [{ src: 'https://localhost/image.png', title: 'image.png' }],
    }

    await wrapper.events.click(await wrapper.findByRole('button', { name: 'Close image preview' }))

    expect(imageViewerOptions.value.visible).toBe(false)
  })

  describe('image navigation', () => {
    it('disables the previous action on the first image', async () => {
      const wrapper = renderComponent(CommonImageViewer)

      imageViewerOptions.value = { visible: true, index: 0, images }

      expect(await wrapper.findByRole('button', { name: 'Previous image' })).toHaveAttribute(
        'aria-disabled',
        'true',
      )
      expect(wrapper.getByRole('button', { name: 'Next image' })).not.toHaveAttribute(
        'aria-disabled',
      )
    })

    it('disables the next action on the last image', async () => {
      const wrapper = renderComponent(CommonImageViewer)

      imageViewerOptions.value = { visible: true, index: images.length - 1, images }

      expect(await wrapper.findByRole('button', { name: 'Next image' })).toHaveAttribute(
        'aria-disabled',
        'true',
      )
      expect(wrapper.getByRole('button', { name: 'Previous image' })).not.toHaveAttribute(
        'aria-disabled',
      )
    })

    it('enables both actions while navigating in between', async () => {
      const wrapper = renderComponent(CommonImageViewer)

      imageViewerOptions.value = { visible: true, index: 0, images }

      await wrapper.events.click(await wrapper.findByRole('button', { name: 'Next image' }))

      expect(wrapper.getByRole('button', { name: 'Previous image' })).not.toHaveAttribute(
        'aria-disabled',
      )
      expect(wrapper.getByRole('button', { name: 'Next image' })).not.toHaveAttribute(
        'aria-disabled',
      )
    })

    it('disables the next action after navigating to the last image', async () => {
      const wrapper = renderComponent(CommonImageViewer)

      imageViewerOptions.value = { visible: true, index: images.length - 2, images }

      await wrapper.events.click(await wrapper.findByRole('button', { name: 'Next image' }))

      expect(wrapper.getByRole('button', { name: 'Next image' })).toHaveAttribute(
        'aria-disabled',
        'true',
      )
    })

    it('resets the navigation state when the viewer is reopened', async () => {
      const wrapper = renderComponent(CommonImageViewer)

      imageViewerOptions.value = { visible: true, index: 0, images }

      await wrapper.events.click(await wrapper.findByRole('button', { name: 'Next image' }))

      imageViewerOptions.value = { visible: false, index: 0, images: [] }
      imageViewerOptions.value = { visible: true, index: 0, images }

      expect(await wrapper.findByRole('button', { name: 'Previous image' })).toHaveAttribute(
        'aria-disabled',
        'true',
      )
    })

    it('reverses the chevrons in RTL locales', async () => {
      const wrapper = renderComponent(CommonImageViewer)
      const locale = useLocaleStore()

      imageViewerOptions.value = { visible: true, index: 1, images }

      const previousButton = await wrapper.findByRole('button', { name: 'Previous image' })
      const nextButton = wrapper.getByRole('button', { name: 'Next image' })

      expect(buildIconsQueries(previousButton).getByIconName('chevron-left')).toBeInTheDocument()
      expect(buildIconsQueries(nextButton).getByIconName('chevron-right')).toBeInTheDocument()

      locale.localeData = { dir: EnumTextDirection.Rtl } as never

      await waitFor(() => {
        expect(buildIconsQueries(previousButton).getByIconName('chevron-right')).toBeInTheDocument()
        expect(buildIconsQueries(nextButton).getByIconName('chevron-left')).toBeInTheDocument()
      })
    })

    it('navigates forward and backward with arrow keys in LTR locales', async () => {
      const wrapper = renderComponent(CommonImageViewer)

      imageViewerOptions.value = { visible: true, index: 1, images }

      await wrapper.events.keyboard('{ArrowRight}')

      expect(await wrapper.findByRole('button', { name: 'Next image' })).toHaveAttribute(
        'aria-disabled',
        'true',
      )

      await wrapper.events.keyboard('{ArrowLeft}')
      await wrapper.events.keyboard('{ArrowLeft}')

      expect(await wrapper.findByRole('button', { name: 'Previous image' })).toHaveAttribute(
        'aria-disabled',
        'true',
      )
    })

    it('mirrors arrow key navigation in RTL locales', async () => {
      const wrapper = renderComponent(CommonImageViewer)
      const locale = useLocaleStore()

      locale.localeData = { dir: EnumTextDirection.Rtl } as never
      imageViewerOptions.value = { visible: true, index: 1, images }

      await wrapper.events.keyboard('{ArrowLeft}')

      expect(await wrapper.findByRole('button', { name: 'Next image' })).toHaveAttribute(
        'aria-disabled',
        'true',
      )

      await wrapper.events.keyboard('{ArrowRight}')
      await wrapper.events.keyboard('{ArrowRight}')

      expect(await wrapper.findByRole('button', { name: 'Previous image' })).toHaveAttribute(
        'aria-disabled',
        'true',
      )
    })
  })
})
