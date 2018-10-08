window.jQuery = require('jquery')
const $ = window.jQuery

require('../chat.js')

const chatHTML = require('./chat.view.js')
const show = jest.fn()

window.ZammadChat.prototype.show = show
window.ZammadChat.prototype.view = (name) => () => name === 'chat' ? chatHTML : '<div />'
window.ZammadIo.prototype.send = jest.fn()

describe('ZammadChat', () => {
  describe('when chat is hidden', () => {
    const chat = new window.ZammadChat({
      chatId: 1,
      show: false
    })
    const addClass = jest.fn()
    const removeClass = jest.fn()

    beforeEach(() => {
      jQuery.prototype.addClass = addClass
      jQuery.prototype.removeClass = removeClass
    })

    afterEach(() => {
      jQuery.prototype.addClass.mockRestore()
      jQuery.prototype.removeClass.mockRestore()
    })

    describe('when open', () => {
      it('calls show function', () => {
        chat.renderBase()
        chat.open()

        expect(show).toHaveBeenCalled()
      })

      it('hides button', () => {
        chat.renderBase()
        chat.open()

        expect(addClass).toHaveBeenCalledWith(chat.options.inactiveClass)
      })
    })

    describe('when close', () => {
      it('shows button', () => {
        window.ZammadChat.prototype.isOpen = true
        window.ZammadChat.prototype.sessionId = 1
        window.ZammadChat.prototype.initDelayId = null
        window.ZammadChat.prototype.sessionClose = jest.fn()

        const chat = new window.ZammadChat({
          chatId: 1,
          show: false
        })

        chat.renderBase()
        chat.close()

        expect(removeClass).toHaveBeenCalledWith(chat.options.inactiveClass)
      })
    })

    describe('when render', () => {
      it('adds `inactiveClass` to button', () => {
        chat.render()

        expect(addClass).toHaveBeenCalledWith(chat.options.inactiveClass)
      })
    })

    describe('when onReady', () => {
      it('removes `inactiveClass` from the button', () => {
        chat.onReady()

        expect(removeClass).toHaveBeenCalledWith(chat.options.inactiveClass)
      })
    })
  })
})
