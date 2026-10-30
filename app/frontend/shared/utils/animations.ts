// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

const hasAncestorAnimation = (element: HTMLElement) =>
  (document.getAnimations?.() ?? []).some((animation) =>
    (animation.effect as KeyframeEffect | null)?.target?.contains(element),
  )

export const waitForAncestorAnimations = (
  element: HTMLElement,
  options = { idle_frames: 3, max_wait_ms: 1000 },
) =>
  new Promise<void>((resolve) => {
    const startedAt = performance.now()
    let idleFrames = 0

    const checkFrame = () => {
      idleFrames = hasAncestorAnimation(element) ? 0 : idleFrames + 1

      if (idleFrames >= options.idle_frames || performance.now() - startedAt > options.max_wait_ms)
        resolve()
      else requestAnimationFrame(checkFrame)
    }

    requestAnimationFrame(checkFrame)
  })
