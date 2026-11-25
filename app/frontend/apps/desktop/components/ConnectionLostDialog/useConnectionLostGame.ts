// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'

export const GAME_WIDTH = 600
export const GAME_HEIGHT = 200

export const BIRD_X = 40
export const BIRD_WIDTH = 36
export const BIRD_HEIGHT = 33
export const BIRD_MAX_VELOCITY = 260

const BIRD_START_Y = (GAME_HEIGHT - BIRD_HEIGHT) / 2
const BIRD_MAX_Y = GAME_HEIGHT - BIRD_HEIGHT
// How quickly the bird reaches its full vertical speed and comes to rest again.
const BIRD_RESPONSIVENESS = 12

const START_SPEED = 260
const MAX_SPEED = 620
const ACCELERATION = 8
const SCORE_PER_PIXEL = 0.1
// Keeps a player still holding an arrow key from restarting right away.
const RESTART_DELAY = 600

// The bird's outline is far from rectangular, so the hitbox is forgiving.
const HITBOX_INSET = 7

const PAPER_STACKS = [
  { width: 22, height: 28 },
  { width: 22, height: 42 },
  { width: 46, height: 28 },
  { width: 46, height: 42 },
] as const

const SECOND_STACK_CHANCE = 0.5
const SECOND_STACK_MAX_OFFSET = 80

type GameStatus = 'idle' | 'running' | 'over'

export type SteeringDirection = -1 | 0 | 1

export interface Obstacle {
  id: number
  x: number
  y: number
  width: number
  height: number
}

const highScore = ref(0)

const randomBetween = (min: number, max: number) => min + Math.random() * (max - min)

const randomStack = () => PAPER_STACKS[Math.floor(Math.random() * PAPER_STACKS.length)]

const overlaps = (obstacle: Obstacle, birdY: number) =>
  BIRD_X + HITBOX_INSET < obstacle.x + obstacle.width &&
  BIRD_X + BIRD_WIDTH - HITBOX_INSET > obstacle.x &&
  birdY + HITBOX_INSET < obstacle.y + obstacle.height &&
  birdY + BIRD_HEIGHT - HITBOX_INSET > obstacle.y

export const useConnectionLostGame = () => {
  const status = ref<GameStatus>('idle')
  const distance = ref(0)
  const speed = ref(START_SPEED)

  const bird = ref({ y: BIRD_START_Y, velocity: 0 })
  const obstacles = ref<Obstacle[]>([])

  let direction: SteeringDirection = 0
  let nextObstacleId = 0
  let gameOverAt = 0
  let distanceToNextWave = 0

  const score = computed(() => Math.floor(distance.value * SCORE_PER_PIXEL))

  const addObstacle = (x: number, minY: number, maxY: number) => {
    const stack = randomStack()

    obstacles.value.push({
      id: nextObstacleId++,
      x,
      y: randomBetween(minY, maxY - stack.height),
      ...stack,
    })
  }

  // A wave of two keeps one stack in each half, which always leaves a gap the bird fits through.
  const spawnWave = () => {
    if (Math.random() < SECOND_STACK_CHANCE) {
      addObstacle(GAME_WIDTH, 0, GAME_HEIGHT / 2)
      addObstacle(
        GAME_WIDTH + randomBetween(0, SECOND_STACK_MAX_OFFSET),
        GAME_HEIGHT / 2,
        GAME_HEIGHT,
      )
    } else {
      addObstacle(GAME_WIDTH, 0, GAME_HEIGHT)
    }

    distanceToNextWave = randomBetween(240, 440) + speed.value * 0.3
  }

  const reset = () => {
    distance.value = 0
    speed.value = START_SPEED
    bird.value.y = BIRD_START_Y
    bird.value.velocity = 0
    obstacles.value = []
    distanceToNextWave = GAME_WIDTH / 2
  }

  const steer = (newDirection: SteeringDirection) => {
    direction = newDirection

    if (status.value === 'running' || newDirection === 0) return
    if (status.value === 'over' && Date.now() - gameOverAt < RESTART_DELAY) return

    reset()
    status.value = 'running'
  }

  const gameOver = () => {
    status.value = 'over'
    gameOverAt = Date.now()
    highScore.value = Math.max(highScore.value, score.value)
  }

  const moveBird = (seconds: number) => {
    const targetVelocity = direction * BIRD_MAX_VELOCITY

    bird.value.velocity +=
      (targetVelocity - bird.value.velocity) * Math.min(1, BIRD_RESPONSIVENESS * seconds)

    const y = bird.value.y + bird.value.velocity * seconds

    bird.value.y = Math.min(BIRD_MAX_Y, Math.max(0, y))
    if (bird.value.y !== y) bird.value.velocity = 0
  }

  const moveObstacles = (travelled: number) => {
    obstacles.value.forEach((obstacle) => {
      obstacle.x -= travelled
    })
    obstacles.value = obstacles.value.filter((obstacle) => obstacle.x + obstacle.width > 0)

    distanceToNextWave -= travelled
    if (distanceToNextWave <= 0) spawnWave()
  }

  const step = (seconds: number) => {
    if (status.value !== 'running') return

    const travelled = speed.value * seconds

    distance.value += travelled
    speed.value = Math.min(MAX_SPEED, speed.value + ACCELERATION * seconds)

    moveBird(seconds)
    moveObstacles(travelled)

    if (obstacles.value.some((obstacle) => overlaps(obstacle, bird.value.y))) gameOver()
  }

  return {
    status,
    score,
    highScore,
    distance,
    bird,
    obstacles,
    steer,
    step,
  }
}
