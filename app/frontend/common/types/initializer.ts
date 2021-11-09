import { App } from 'vue'

export type InitializerModule = (app: App) => void

export interface Initializer {
  app: App
  modules: Array<InitializerModule>
  initialize(): void
}
