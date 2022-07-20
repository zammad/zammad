// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

export const mergeArray = <T extends unknown[]>(a: T, b: T) => {
  return [...new Set([...a, ...b])]
}

export const waitForAnimationFrame = () => {
  return new Promise((resolve) => requestAnimationFrame(resolve))
}
