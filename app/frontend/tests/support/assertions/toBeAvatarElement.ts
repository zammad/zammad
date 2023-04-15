// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { prettyDOM } from '@testing-library/vue'

export interface ToBeAvatarOptions {
  vip?: boolean
  outOfOffice?: boolean
  active?: boolean
  image?: string
  type: 'user' | 'organization'
}

// eslint-disable-next-line sonarjs/cognitive-complexity
export default function toBeAvatar(
  this: any,
  received: unknown,
  options: ToBeAvatarOptions,
) {
  if (!received || !(received instanceof HTMLElement)) {
    return {
      message: () => 'received is not an HTMLElement',
      pass: false,
    }
  }

  if (received.dataset.testId !== 'common-avatar') {
    return {
      message: () =>
        `received element is not an avatar\n${prettyDOM(received)}`,
      pass: false,
    }
  }

  if (!options) {
    return {
      message: () => 'received element is an avatar',
      pass: true,
    }
  }

  let pass = true
  const errors: string[] = []

  if (options.vip != null) {
    const icon = received.querySelector('use[href="#icon-mobile-crown"]')
    const localPass = options.vip ? !!icon : !icon
    if (!localPass) {
      errors.push(`vip icon is ${options.vip ? 'missing' : 'present'}`)
    }
    pass = pass && localPass
  }

  if (options.outOfOffice != null) {
    const isOutOfOffice =
      received.classList.contains('opacity-100') &&
      received.classList.contains('grayscale-[70%]')
    const localPass = options.outOfOffice ? isOutOfOffice : !isOutOfOffice
    if (!localPass) {
      errors.push(
        `out of office class is ${options.outOfOffice ? 'missing' : 'present'}`,
      )
    }
    pass = pass && localPass
  }

  if (options.active != null) {
    const isActive =
      options.type === 'user'
        ? !received.classList.contains('opacity-20 grayscale')
        : !!received.querySelector('use[href="#icon-mobile-organization"]')
    const localPass = options.active ? isActive : !isActive
    if (!localPass) {
      errors.push(`active class is ${options.active ? 'missing' : 'present'}`)
    }
    pass = pass && isActive
  }

  if (options.image != null) {
    if (options.type === 'organization') {
      pass = false
      errors.push(`organization avatar doesn't have an image`)
    } else {
      const style = window.getComputedStyle(received)
      const imageStyle = `url(/api/users/image/${options.image})`
      const hasImage = style.backgroundImage === imageStyle
      if (!hasImage) {
        errors.push(
          `avatar has image ${style.backgroundImage} instead of ${imageStyle}`,
        )
      }
      pass = pass && hasImage
    }
  }

  return {
    message: () =>
      `received element is${
        this.isNot ? '' : ' not'
      } a correct avatar: ${errors.join('\n')}\n${prettyDOM(received)}`,
    pass,
  }
}
