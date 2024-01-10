// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { renderComponent } from '#tests/support/components/index.ts'

const renderImageUploadInput = (props: Record<string, unknown> = {}) => {
  return renderComponent(FormKit, {
    props: {
      id: 'imageUpload',
      type: 'imageUpload',
      name: 'imageUpload',
      label: 'Image Upload',
      formId: 'form',
      ...props,
    },
    form: true,
    router: true,
  })
}

const dataURItoBlob = (dataURI: string) => {
  const byteString = atob(dataURI.split(',')[1])
  const mimeString = dataURI.split(',')[0].split(':')[1].split(';')[0]

  const ab = new ArrayBuffer(byteString.length)
  const ia = new Uint8Array(ab)
  for (let i = 0; i < byteString.length; i += 1) {
    ia[i] = byteString.charCodeAt(i)
  }

  return new Blob([ab], { type: mimeString })
}

describe('Fields - FieldImageUpload', () => {
  it('renders upload image file button', async () => {
    const view = renderImageUploadInput()

    const uploadImageButton = view.getByRole('button', { name: 'Upload image' })
    expect(uploadImageButton).toBeInTheDocument()

    const imageUploadInput = view.getByTestId('imageUploadInput')

    const clickSpy = vi.spyOn(imageUploadInput, 'click')

    await view.events.click(uploadImageButton)

    expect(
      clickSpy,
      'trigger click on button, which normally opens a window to choose file',
    ).toHaveBeenCalled()
  })

  it('renders preview of the uploaded image file', async () => {
    const view = renderImageUploadInput()

    const imageUploadInput = view.getByTestId('imageUploadInput')

    const testValue =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVQYV2NgYAAAAAMAAWgmWQ0AAAAASUVORK5CYII='

    const testFile = new File([dataURItoBlob(testValue)], 'foo.png', {
      type: 'image/png',
    })

    await view.events.upload(imageUploadInput, testFile)

    await vi.waitFor(() => {
      expect(getNode('imageUpload')?._value).toEqual(testValue)

      const uploadImage = view.getByRole('img', { name: 'Image preview' })

      expect(uploadImage).toHaveAttribute('src', testValue)
    })
  })

  it('renders passed value as image preview', async () => {
    const testValue = '/api/v1/system_assets/product_logo/1704708731'

    const view = renderImageUploadInput({
      value: testValue,
    })

    const uploadImage = view.getByRole('img', { name: 'Image preview' })

    expect(uploadImage).toHaveAttribute('src', testValue)
  })

  it('supports removal of the uploaded image', async () => {
    const view = renderImageUploadInput({
      value: '/api/v1/system_assets/product_logo/1704708731',
    })

    const removeImageButton = view.getByRole('button', { name: 'Remove image' })

    await view.events.click(removeImageButton)

    expect(
      view.queryByRole('button', { name: 'Remove image' }),
    ).not.toBeInTheDocument()

    expect(getNode('imageUpload')?._value).toEqual('')
  })

  it('supports disabled prop', async () => {
    const view = renderImageUploadInput({
      disabled: true,
    })

    const clickEvent = vi.fn()
    HTMLInputElement.prototype.click = clickEvent

    const uploadImageButton = view.getByRole('button', { name: 'Upload image' })

    expect(uploadImageButton).toBeDisabled()

    await view.events.click(uploadImageButton)

    expect(clickEvent).not.toHaveBeenCalled()
  })
})
