// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { dataURItoBlob } from '#tests/support/utils.ts'

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

  it('renders placeholder value as image preview', async () => {
    const testValue = '/api/v1/system_assets/product_logo/1704708731'

    const view = renderImageUploadInput({
      placeholderImagePath: testValue,
    })

    const uploadImage = view.getByRole('img', { name: 'Image preview' })

    expect(uploadImage).toHaveAttribute('src', testValue)
  })

  it('does not allow to remove placeholder image', async () => {
    const view = renderImageUploadInput({
      placeholderImagePath: '/api/v1/system_assets/product_logo/1704708731',
    })

    expect(
      view.queryByRole('button', { name: 'Remove image' }),
    ).not.toBeInTheDocument()
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

  it('shows placeholder image after removing uploaded image', async () => {
    const placeholder = '/api/v1/system_assets/product_logo/placeholder'
    const value = '/api/v1/system_assets/product_logo/value'

    const view = renderImageUploadInput({
      placeholderImagePath: placeholder,
      value,
    })

    const uploadImage = view.getByRole('img', { name: 'Image preview' })

    expect(uploadImage).toHaveAttribute('src', value)

    const removeImageButton = view.getByRole('button', { name: 'Remove image' })

    await view.events.click(removeImageButton)

    expect(uploadImage).toHaveAttribute('src', placeholder)
  })
})

// Cover all use cases from the FormKit custom input checklist.
//   More info here: https://formkit.com/essentials/custom-inputs#input-checklist
describe('Fields - FieldImageUpload - Input Checklist', () => {
  it('implements input id attribute', async () => {
    const view = renderImageUploadInput({
      id: 'test_id',
    })

    expect(view.getByLabelText('Image Upload')).toHaveAttribute('id', 'test_id')
  })

  it('implements input name', async () => {
    const view = renderImageUploadInput({
      name: 'test_name',
    })

    expect(view.getByLabelText('Image Upload')).toHaveAttribute(
      'name',
      'test_name',
    )
  })

  it('implements blur handler', async () => {
    const blurHandler = vi.fn()

    const view = renderImageUploadInput({
      onBlur: blurHandler,
    })

    view.getByLabelText('Image Upload').focus()

    await view.events.tab()

    expect(blurHandler).toHaveBeenCalledOnce()
  })

  it('implements input handler', async () => {
    const view = renderImageUploadInput()

    const imageUploadInput = view.getByTestId('imageUploadInput')

    const testValue =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVQYV2NgYAAAAAMAAWgmWQ0AAAAASUVORK5CYII='

    const testFile = new File([dataURItoBlob(testValue)], 'foo.png', {
      type: 'image/png',
    })

    await view.events.upload(imageUploadInput, testFile)

    await vi.waitFor(() => {
      expect(getNode('imageUpload')?.value).toEqual(testValue)

      const uploadImage = view.getByRole('img', { name: 'Image preview' })

      expect(uploadImage).toHaveAttribute('src', testValue)
    })
  })

  it('implements input value display', async () => {
    const testValue = '/api/v1/system_assets/product_logo/1704708731'

    const view = renderImageUploadInput({
      value: testValue,
    })

    const uploadImage = view.getByRole('img', { name: 'Image preview' })

    expect(uploadImage).toHaveAttribute('src', testValue)
  })

  it('implements disabled', async () => {
    const view = renderImageUploadInput({
      disabled: true,
    })

    expect(view.getByLabelText('Image Upload')).toBeDisabled()

    const clickEvent = vi.fn()
    HTMLInputElement.prototype.click = clickEvent

    const uploadImageButton = view.getByRole('button', { name: 'Upload image' })

    expect(uploadImageButton).toBeDisabled()

    await view.events.click(uploadImageButton)

    expect(clickEvent).not.toHaveBeenCalled()
  })

  it('implements attribute passthrough', async () => {
    const view = renderImageUploadInput({
      'test-attribute': 'test_value',
    })

    expect(view.getByLabelText('Image Upload')).toHaveAttribute(
      'test-attribute',
      'test_value',
    )
  })

  it('implements standardized classes', async () => {
    const view = renderImageUploadInput()

    expect(view.getByLabelText('Image Upload')).toHaveClass('formkit-input')
  })
})
