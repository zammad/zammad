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

    it('calls show function', () => {
      chat.renderBase()
      chat.open()

      expect(show).toHaveBeenCalled()
    })
  })
})
