// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  BIRD_HEIGHT,
  GAME_HEIGHT,
  GAME_WIDTH,
  useConnectionLostGame,
} from '../useConnectionLostGame.ts'

const FRAME = 1 / 60
const BIRD_START_Y = (GAME_HEIGHT - BIRD_HEIGHT) / 2

const runFor = (game: ReturnType<typeof useConnectionLostGame>, seconds: number) => {
  for (let elapsed = 0; elapsed < seconds; elapsed += FRAME) game.step(FRAME)
}

describe('useConnectionLostGame', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
    if (vi.isMockFunction(Math.random)) vi.mocked(Math.random).mockRestore()
  })

  it('waits in the middle until the bird is steered', () => {
    const game = useConnectionLostGame()

    runFor(game, 1)

    expect(game.status.value).toBe('idle')
    expect(game.bird.value.y).toBe(BIRD_START_Y)
    expect(game.distance.value).toBe(0)
    expect(game.obstacles.value).toHaveLength(0)
  })

  it('moves the bird while steering and stops at the edges', () => {
    const game = useConnectionLostGame()

    game.steer(-1)
    runFor(game, 0.15)

    expect(game.status.value).toBe('running')
    expect(game.bird.value.y).toBeLessThan(BIRD_START_Y)

    runFor(game, 1)

    expect(game.bird.value.y).toBe(0)
    expect(game.bird.value.velocity).toBe(0)

    game.steer(1)
    runFor(game, 1.5)

    expect(game.bird.value.y).toBe(GAME_HEIGHT - BIRD_HEIGHT)
  })

  it('lets the bird come to rest when the steering stops', () => {
    const game = useConnectionLostGame()

    game.steer(1)
    runFor(game, 0.1)
    game.steer(0)
    runFor(game, 0.5)

    const { y } = game.bird.value

    runFor(game, 0.1)

    expect(game.bird.value.y).toBeCloseTo(y, 1)
  })

  it('does not start without a steering direction', () => {
    const game = useConnectionLostGame()

    game.steer(0)

    expect(game.status.value).toBe('idle')
  })

  it('spawns paper stacks at varying heights which drift towards the bird', () => {
    const game = useConnectionLostGame()

    game.steer(-1)
    runFor(game, 1.2)

    const [obstacle] = game.obstacles.value

    expect(obstacle.x).toBeLessThan(GAME_WIDTH)
    expect(obstacle.y).toBeGreaterThanOrEqual(0)
    expect(obstacle.y + obstacle.height).toBeLessThanOrEqual(GAME_HEIGHT)

    const { x } = obstacle

    game.step(FRAME)

    expect(obstacle.x).toBeLessThan(x)
  })

  it('keeps the stacks of a wave in different halves', () => {
    vi.spyOn(Math, 'random').mockReturnValue(0)

    const game = useConnectionLostGame()

    game.steer(-1)
    runFor(game, 1.2)

    const [upper, lower] = game.obstacles.value

    expect(upper.y + upper.height).toBeLessThanOrEqual(GAME_HEIGHT / 2)
    expect(lower.y).toBeGreaterThanOrEqual(GAME_HEIGHT / 2)
  })

  it('ends the game on a collision and keeps the high score', () => {
    // A single stack, centred like the bird.
    vi.spyOn(Math, 'random').mockReturnValue(0.5)

    const game = useConnectionLostGame()

    game.steer(1)
    game.steer(0)
    runFor(game, 5)

    expect(game.status.value).toBe('over')
    expect(game.score.value).toBeGreaterThan(0)
    expect(game.highScore.value).toBe(game.score.value)

    const score = game.score.value

    runFor(game, 1)

    expect(game.score.value).toBe(score)
  })

  it('restarts only after a short delay', () => {
    vi.spyOn(Math, 'random').mockReturnValue(0.5)

    const game = useConnectionLostGame()

    game.steer(1)
    game.steer(0)
    runFor(game, 5)

    game.steer(-1)

    expect(game.status.value).toBe('over')

    vi.advanceTimersByTime(1000)
    game.steer(-1)

    expect(game.status.value).toBe('running')
    expect(game.score.value).toBe(0)
    expect(game.bird.value.y).toBe(BIRD_START_Y)
    expect(game.obstacles.value).toHaveLength(0)
  })
})
