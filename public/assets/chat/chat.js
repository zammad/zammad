if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["agent"] = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      if (this.agent.avatar) {
        __out.push('\n<img class="zammad-chat-agent-avatar" src="');
        __out.push(__sanitize(this.agent.avatar));
        __out.push('">\n');
      }
    
      __out.push('\n<span class="zammad-chat-agent-sentence">\n  <span class="zammad-chat-agent-name">');
    
      __out.push(__sanitize(this.agent.name));
    
      __out.push('</span> ');
    
      __out.push(this.agentPhrase);
    
      __out.push('\n</span>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  slice = [].slice;

(function($, window) {
  var ZammadChat;
  ZammadChat = (function() {
    ZammadChat.prototype.defaults = {
      invitationPhrase: '<strong>Chat</strong> with us!',
      agentPhrase: ' is helping you',
      show: true,
      target: $('body')
    };

    ZammadChat.prototype._messageCount = 0;

    ZammadChat.prototype.isOpen = false;

    ZammadChat.prototype.blinkOnlineInterval = null;

    ZammadChat.prototype.stopBlinOnlineStateTimeout = null;

    ZammadChat.prototype.showTimeEveryXMinutes = 1;

    ZammadChat.prototype.lastTimestamp = null;

    ZammadChat.prototype.lastAddedType = null;

    ZammadChat.prototype.inputTimeout = null;

    ZammadChat.prototype.isTyping = false;

    ZammadChat.prototype.isOnline = true;

    ZammadChat.prototype.initialQueueDelay = 10000;

    ZammadChat.prototype.debug = true;

    ZammadChat.prototype.host = 'ws://localhost:6042';

    ZammadChat.prototype.strings = {
      'Online': 'Online',
      'Offline': 'Offline',
      'Connecting': 'Verbinden',
      'Connection re-established': 'Connection re-established',
      'Today': 'Heute',
      'Send': 'Senden',
      'Compose your message...': 'Ihre Nachricht...',
      'All colleges are busy.': 'Alle Kollegen sind belegt.',
      'You are on waiting list position <strong>%s</strong>.': 'Sie sind in der Warteliste an der Position <strong>%s</strong>.',
      '': '',
      '': '',
      '': ''
    };

    ZammadChat.prototype.sessionId = void 0;

    ZammadChat.prototype.T = function() {
      var i, item, items, len, string, translation;
      string = arguments[0], items = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      if (!this.strings[string]) {
        this.log('notice', "Translation needed for '" + string + "'");
      }
      translation = this.strings[string] || string;
      if (items) {
        for (i = 0, len = items.length; i < len; i++) {
          item = items[i];
          translation = translation.replace(/%s/, item);
        }
      }
      return translation;
    };

    ZammadChat.prototype.log = function() {
      var level, string;
      level = arguments[0], string = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      if (!this.debug && level === 'debug') {
        return;
      }
      return console.log(level, string);
    };

    ZammadChat.prototype.view = function(name) {
      return (function(_this) {
        return function(options) {
          if (!options) {
            options = {};
          }
          options.T = _this.T;
          return window.zammadChatTemplates[name](options);
        };
      })(this);
    };

    function ZammadChat(el, options) {
      this.setAgentOnlineState = bind(this.setAgentOnlineState, this);
      this.onConnectionEstablished = bind(this.onConnectionEstablished, this);
      this.setSessionId = bind(this.setSessionId, this);
      this.onConnectionReestablished = bind(this.onConnectionReestablished, this);
      this.reconnect = bind(this.reconnect, this);
      this.onWebSocketOpen = bind(this.onWebSocketOpen, this);
      this.connect = bind(this.connect, this);
      this.onAgentTypingEnd = bind(this.onAgentTypingEnd, this);
      this.onAgentTypingStart = bind(this.onAgentTypingStart, this);
      this.onQueue = bind(this.onQueue, this);
      this.onQueueScreen = bind(this.onQueueScreen, this);
      this.onCloseAnimationEnd = bind(this.onCloseAnimationEnd, this);
      this.closeWindow = bind(this.closeWindow, this);
      this.close = bind(this.close, this);
      this.onOpenAnimationEnd = bind(this.onOpenAnimationEnd, this);
      this.open = bind(this.open, this);
      this.renderMessage = bind(this.renderMessage, this);
      this.receiveMessage = bind(this.receiveMessage, this);
      this.onSubmit = bind(this.onSubmit, this);
      this.onTypingEnd = bind(this.onTypingEnd, this);
      this.onInput = bind(this.onInput, this);
      this.openSession = bind(this.openSession, this);
      this.onReady = bind(this.onReady, this);
      this.onWebSocketMessage = bind(this.onWebSocketMessage, this);
      this.send = bind(this.send, this);
      this.checkForEnter = bind(this.checkForEnter, this);
      this.view = bind(this.view, this);
      this.log = bind(this.log, this);
      this.T = bind(this.T, this);
      this.options = $.extend({}, this.defaults, options);
      this.el = $(this.view('chat')(this.options));
      this.options.target.append(this.el);
      this.input = this.el.find('.zammad-chat-input');
      this.el.find('.js-chat-open').click(this.open);
      this.el.find('.js-chat-close').click(this.close);
      this.el.find('.zammad-chat-controls').on('submit', this.onSubmit);
      this.input.on({
        keydown: this.checkForEnter,
        input: this.onInput
      });
      if (!window.WebSocket || !sessionStorage) {
        this.log('notice', 'Chat: Browser not supported!');
        return;
      }
      this.connect();
    }

    ZammadChat.prototype.checkForEnter = function(event) {
      if (!event.shiftKey && event.keyCode === 13) {
        event.preventDefault();
        return this.sendMessage();
      }
    };

    ZammadChat.prototype.send = function(event, data) {
      var pipe;
      this.log('debug', 'ws:send', event, data);
      pipe = JSON.stringify({
        event: event,
        data: data
      });
      return this.ws.send(pipe);
    };

    ZammadChat.prototype.onWebSocketMessage = function(e) {
      var i, len, pipe, pipes;
      pipes = JSON.parse(e.data);
      for (i = 0, len = pipes.length; i < len; i++) {
        pipe = pipes[i];
        this.log('debug', 'ws:onmessage', pipe);
        switch (pipe.event) {
          case 'chat_session_message':
            if (pipe.data.self_written) {
              return;
            }
            this.receiveMessage(pipe.data);
            break;
          case 'chat_session_typing':
            if (pipe.data.self_written) {
              return;
            }
            this.onAgentTypingStart();
            break;
          case 'chat_session_start':
            this.onConnectionEstablished(pipe.data);
            break;
          case 'chat_session_queue':
            this.onQueue(pipe.data);
            break;
          case 'chat_session_closed':
            this.onSessionClosed(pipe.data);
            break;
          case 'chat_session_left':
            this.onSessionClosed(pipe.data);
            break;
          case 'chat_status_customer':
            switch (pipe.data.state) {
              case 'online':
                this.onReady();
                this.log('debug', 'Zammad Chat: ready');
                break;
              case 'offline':
                this.log('debug', 'Zammad Chat: No agent online');
                break;
              case 'chat_disabled':
                this.log('debug', 'Zammad Chat: Chat is disabled');
                break;
              case 'no_seats_available':
                this.log('debug', 'Zammad Chat: Too many clients in queue. Clients in queue: ', pipe.data.queue);
                break;
              case 'reconnect':
                this.log('debug', 'old messages', pipe.data.session);
                this.openSession(pipe.data.session);
            }
        }
      }
    };

    ZammadChat.prototype.onReady = function() {
      if (this.options.show) {
        return this.show();
      }
    };

    ZammadChat.prototype.openSession = function(session) {
      var i, len, message, unfinishedMessage;
      unfinishedMessage = sessionStorage.getItem('unfinished_message');
      for (i = 0, len = session.length; i < len; i++) {
        message = session[i];
        console.log("message in session", message);
        this.renderMessage({
          message: message.content,
          id: message.id,
          from: message.created_by_id ? 'agent' : 'customer'
        });
      }
      if (unfinishedMessage) {
        this.input.val(unfinishedMessage);
      }
      this.show();
      this.open({
        showLoader: false,
        animate: false
      });
      if (unfinishedMessage) {
        return this.input.focus();
      }
    };

    ZammadChat.prototype.onInput = function() {
      this.el.find('.zammad-chat-message--unread').removeClass('zammad-chat-message--unread');
      sessionStorage.setItem('unfinished_message', this.input.val());
      return this.onTypingStart();
    };

    ZammadChat.prototype.onTypingStart = function() {
      if (this.isTypingTimeout) {
        clearTimeout(this.isTypingTimeout);
      }
      this.isTypingTimeout = setTimeout(this.onTypingEnd, 1500);
      if (!this.isTyping) {
        this.isTyping = true;
        return this.send('chat_session_typing', {
          session_id: this.sessionId
        });
      }
    };

    ZammadChat.prototype.onTypingEnd = function() {
      return this.isTyping = false;
    };

    ZammadChat.prototype.onSubmit = function(event) {
      event.preventDefault();
      return this.sendMessage();
    };

    ZammadChat.prototype.sendMessage = function() {
      var message, messageElement;
      message = this.input.val();
      if (!message) {
        return;
      }
      sessionStorage.removeItem('unfinished_message');
      messageElement = this.view('message')({
        message: message,
        from: 'customer',
        id: this._messageCount++
      });
      this.maybeAddTimestamp();
      if (this.el.find('.zammad-chat-message--typing').size()) {
        this.lastAddedType = 'typing-placeholder';
        this.el.find('.zammad-chat-message--typing').before(messageElement);
      } else {
        this.lastAddedType = 'message--customer';
        this.el.find('.zammad-chat-body').append(messageElement);
      }
      this.input.val('');
      this.scrollToBottom();
      this.isTyping = false;
      return this.send('chat_session_message', {
        content: message,
        id: this._messageCount,
        session_id: this.sessionId
      });
    };

    ZammadChat.prototype.receiveMessage = function(data) {
      this.onAgentTypingEnd();
      this.maybeAddTimestamp();
      return this.renderMessage({
        message: data.message.content,
        id: data.id,
        from: 'agent'
      });
    };

    ZammadChat.prototype.renderMessage = function(data) {
      var ref, unread;
      this.lastAddedType = "message--" + data.from;
      unread = (ref = document.hidden) != null ? ref : {
        " zammad-chat-message--unread": ""
      };
      this.el.find('.zammad-chat-body').append(this.view('message')(data));
      return this.scrollToBottom();
    };

    ZammadChat.prototype.open = function(options) {
      if (options == null) {
        options = {
          showLoader: true,
          animate: true
        };
      }
      if (this.isOpen) {
        return;
      }
      if (options.showLoader) {
        this.showLoader();
      }
      this.el.addClass('zammad-chat-is-open');
      if (options.animate) {
        this.el.animate({
          bottom: 0
        }, 500, this.onOpenAnimationEnd);
      } else {
        this.el.css('bottom', 0);
        this.onOpenAnimationEnd();
      }
      return this.isOpen = true;
    };

    ZammadChat.prototype.onOpenAnimationEnd = function() {
      return this.session_init();
    };

    ZammadChat.prototype.close = function(event) {
      if (event) {
        event.stopPropagation();
      }
      this.ws.close();
      sessionStorage.removeItem('sessionId');
      sessionStorage.removeItem('unfinished_message');
      return this.closeWindow();
    };

    ZammadChat.prototype.closeWindow = function() {
      var remainerHeight;
      remainerHeight = this.el.height() - this.el.find('.zammad-chat-header').outerHeight();
      return this.el.animate({
        bottom: -remainerHeight
      }, 500, this.onCloseAnimationEnd);
    };

    ZammadChat.prototype.onCloseAnimationEnd = function() {
      this.el.removeClass('zammad-chat-is-open');
      this.disconnect();
      this.isOpen = false;
      return this.send('chat_session_close', {
        session_id: this.sessionId
      });
    };

    ZammadChat.prototype.hide = function() {
      return this.el.removeClass('zammad-chat-is-visible');
    };

    ZammadChat.prototype.show = function() {
      var remainerHeight;
      this.el.addClass('zammad-chat-is-visible');
      remainerHeight = this.el.outerHeight() - this.el.find('.zammad-chat-header').outerHeight();
      this.el.css('bottom', -remainerHeight);
      return this.input.autoGrow({
        extraLine: false
      });
    };

    ZammadChat.prototype.disableInput = function() {
      this.input.prop('disabled', true);
      return this.el.find('.zammad-chat-send').prop('disabled', true);
    };

    ZammadChat.prototype.enableInput = function() {
      this.input.prop('disabled', false);
      return this.el.find('.zammad-chat-send').prop('disabled', false);
    };

    ZammadChat.prototype.onQueueScreen = function(data) {
      var show;
      show = (function(_this) {
        return function() {
          return _this.onQueue(data.position);
        };
      })(this);
      if (this.initialQueueDelay && !this.onInitialQueueDelayId) {
        this.onInitialQueueDelayId = setTimeout(show, this.initialQueueDelay);
        return;
      }
      if (this.onInitialQueueDelayId) {
        clearTimeout(this.onInitialQueueDelayId);
      }
      return show();
    };

    ZammadChat.prototype.onQueue = function(position) {
      this.log('notice', 'onQueue', position);
      this.inQueue = true;
      this.setSessionId(data.session_id);
      return this.el.find('.zammad-chat-body').html(this.view('waiting')({
        position: data.position
      }));
    };

    ZammadChat.prototype.onAgentTypingStart = function() {
      if (this.stopTypingId) {
        clearTimeout(this.stopTypingId);
      }
      this.stopTypingId = setTimeout(this.onAgentTypingEnd, 3000);
      if (this.el.find('.zammad-chat-message--typing').size()) {
        return;
      }
      this.maybeAddTimestamp();
      this.el.find('.zammad-chat-body').append(this.view('typingIndicator')());
      return this.scrollToBottom();
    };

    ZammadChat.prototype.onAgentTypingEnd = function() {
      return this.el.find('.zammad-chat-message--typing').remove();
    };

    ZammadChat.prototype.maybeAddTimestamp = function() {
      var label, time, timestamp;
      timestamp = Date.now();
      if (!this.lastTimestamp || (timestamp - this.lastTimestamp) > this.showTimeEveryXMinutes * 60000) {
        label = this.T('Today');
        time = new Date().toTimeString().substr(0, 5);
        if (this.lastAddedType === 'timestamp') {
          this.updateLastTimestamp(label, time);
          return this.lastTimestamp = timestamp;
        } else {
          this.addStatus(label, time);
          this.lastTimestamp = timestamp;
          return this.lastAddedType = 'timestamp';
        }
      }
    };

    ZammadChat.prototype.updateLastTimestamp = function(label, time) {
      return this.el.find('.zammad-chat-body').find('.zammad-chat-status').last().replaceWith(this.view('status')({
        label: label,
        time: time
      }));
    };

    ZammadChat.prototype.addStatus = function(label, time) {
      return this.el.find('.zammad-chat-body').append(this.view('status')({
        label: label,
        time: time
      }));
    };

    ZammadChat.prototype.scrollToBottom = function() {
      return this.el.find('.zammad-chat-body').scrollTop($('.zammad-chat-body').prop('scrollHeight'));
    };

    ZammadChat.prototype.session_init = function() {
      return this.send('chat_session_init');
    };

    ZammadChat.prototype.connect = function() {
      this.log('notice', "Connecting to " + this.host);
      this.ws = new window.WebSocket(this.host);
      this.ws.onopen = this.onWebSocketOpen;
      this.ws.onmessage = this.onWebSocketMessage;
      this.ws.onclose = (function(_this) {
        return function(e) {
          _this.log('debug', 'close websocket connection');
          _this.reconnect();
          return _this.setAgentOnlineState(false);
        };
      })(this);
      return this.ws.onerror = (function(_this) {
        return function(e) {
          return _this.log('debug', 'ws:onerror', e);
        };
      })(this);
    };

    ZammadChat.prototype.onWebSocketOpen = function() {
      this.sessionId = sessionStorage.getItem('sessionId');
      this.log('debug', 'ws connected');
      this.send('chat_status_customer', {
        session_id: this.sessionId
      });
      return this.setAgentOnlineState(true);
    };

    ZammadChat.prototype.reconnect = function() {
      this.log('notice', 'reconnecting');
      this.disableInput();
      this.lastAddedType = 'status';
      this.el.find('.zammad-chat-agent-status').attr('data-status', 'connecting').text(this.T('Reconnecting'));
      this.addStatus(this.T('Connection lost'));
      if (this.reconnectDelayId) {
        clearTimeout(this.reconnectDelayId);
      }
      return this.reconnectDelayId = setTimeout(this.connect, 5000);
    };

    ZammadChat.prototype.onConnectionReestablished = function() {
      this.lastAddedType = 'status';
      this.el.find('.zammad-chat-agent-status').attr('data-status', 'online').text(this.T('Online'));
      return this.addStatus(this.T('Connection re-established'));
    };

    ZammadChat.prototype.onSessionClosed = function(data) {
      this.addStatus(this.T('Chat closed by %s', data.realname));
      return this.disableInput();
    };

    ZammadChat.prototype.disconnect = function() {
      this.showLoader();
      this.el.find('.zammad-chat-welcome').removeClass('zammad-chat-is-hidden');
      this.el.find('.zammad-chat-agent').addClass('zammad-chat-is-hidden');
      return this.el.find('.zammad-chat-agent-status').addClass('zammad-chat-is-hidden');
    };

    ZammadChat.prototype.setSessionId = function(id) {
      this.sessionId = id;
      return sessionStorage.setItem('sessionId', id);
    };

    ZammadChat.prototype.onConnectionEstablished = function(data) {
      if (this.onInitialQueueDelayId) {
        clearTimeout(this.onInitialQueueDelayId);
      }
      this.inQueue = false;
      this.agent = data.agent;
      this.setSessionId(data.session_id);
      this.el.find('.zammad-chat-agent').html(this.view('agent')({
        agent: this.agent
      }));
      this.enableInput();
      this.el.find('.zammad-chat-body').empty();
      this.el.find('.zammad-chat-welcome').addClass('zammad-chat-is-hidden');
      this.el.find('.zammad-chat-agent').removeClass('zammad-chat-is-hidden');
      this.el.find('.zammad-chat-agent-status').removeClass('zammad-chat-is-hidden');
      return this.input.focus();
    };

    ZammadChat.prototype.showLoader = function() {
      return this.el.find('.zammad-chat-body').html(this.view('loader')());
    };

    ZammadChat.prototype.setAgentOnlineState = function(state) {
      this.isOnline = state;
      return this.el.find('.zammad-chat-agent-status').toggleClass('zammad-chat-is-online', state).text(state ? this.T('Online') : this.T('Offline'));
    };

    return ZammadChat;

  })();
  return $(document).ready(function() {
    return window.zammadChat = new ZammadChat();
  });
})(window.jQuery, window);

/*!
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * <jevin9@gmail.com> wrote this file. As long as you retain this notice you
 * can do whatever you want with this stuff. If we meet some day, and you think
 * this stuff is worth it, you can buy me a beer in return. Jevin O. Sewaruth
 * ----------------------------------------------------------------------------
 *
 * Autogrow Textarea Plugin Version v3.0
 * http://www.technoreply.com/autogrow-textarea-plugin-3-0
 * 
 * THIS PLUGIN IS DELIVERD ON A PAY WHAT YOU WHANT BASIS. IF THE PLUGIN WAS USEFUL TO YOU, PLEASE CONSIDER BUYING THE PLUGIN HERE :
 * https://sites.fastspring.com/technoreply/instant/autogrowtextareaplugin
 *
 * Date: October 15, 2012
 */

jQuery.fn.autoGrow = function(options) {
  return this.each(function() {
    var settings = jQuery.extend({
      extraLine: true,
    }, options);

    var createMirror = function(textarea) {
      jQuery(textarea).after('<div class="autogrow-textarea-mirror"></div>');
      return jQuery(textarea).next('.autogrow-textarea-mirror')[0];
    }

    var sendContentToMirror = function (textarea) {
      mirror.innerHTML = String(textarea.value)
        .replace(/&/g, '&amp;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/ /g, '&nbsp;')
        .replace(/\n/g, '<br />') +
        (settings.extraLine? '.<br/>.' : '')
      ;

      if (jQuery(textarea).height() != jQuery(mirror).height())
        jQuery(textarea).height(jQuery(mirror).height());
    }

    var growTextarea = function () {
      sendContentToMirror(this);
    }

    // Create a mirror
    var mirror = createMirror(this);
    
    // Style the mirror
    mirror.style.display = 'none';
    mirror.style.wordWrap = 'break-word';
    mirror.style.whiteSpace = 'normal';
    mirror.style.padding = jQuery(this).css('paddingTop') + ' ' + 
      jQuery(this).css('paddingRight') + ' ' + 
      jQuery(this).css('paddingBottom') + ' ' + 
      jQuery(this).css('paddingLeft');
      
    mirror.style.width = jQuery(this).css('width');
    mirror.style.fontFamily = jQuery(this).css('font-family');
    mirror.style.fontSize = jQuery(this).css('font-size');
    mirror.style.lineHeight = jQuery(this).css('line-height');

    // Style the textarea
    this.style.overflow = "hidden";
    this.style.minHeight = this.rows+"em";

    // Bind the textarea's event
    this.onkeyup = growTextarea;

    // Fire the event for text already present
    sendContentToMirror(this);

  });
};
if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["chat"] = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat">\n  <div class="zammad-chat-header js-chat-open">\n    <div class="zammad-chat-header-controls">\n      <span class="zammad-chat-agent-status zammad-chat-is-hidden" data-status="online">Online</span>\n      <span class="zammad-chat-header-icon">\n        <svg class="zammad-chat-header-icon-open" viewBox="0 0 13 7"><path d="M10.807 7l1.4-1.428-5-4.9L6.5-.02l-.7.7-4.9 4.9 1.414 1.413L6.5 2.886 10.807 7z" fill-rule="evenodd"/></svg>\n        <svg class="zammad-chat-header-icon-close js-chat-close" viewBox="0 0 13 13"><path d="m2.241.12l-2.121 2.121 4.243 4.243-4.243 4.243 2.121 2.121 4.243-4.243 4.243 4.243 2.121-2.121-4.243-4.243 4.243-4.243-2.121-2.121-4.243 4.243-4.243-4.243" fill-rule="evenodd"/></svg>\n      </span>\n    </div>\n    <div class="zammad-chat-agent zammad-chat-is-hidden">\n    </div>\n    <div class="zammad-chat-welcome">\n      <svg class="zammad-chat-icon" viewBox="0 0 24 24"><path d="M2 5C2 4 3 3 4 3h16c1 0 2 1 2 2v10C22 16 21 17 20 17H4C3 17 2 16 2 15V5zM12 17l6 4v-4h-6z" fill-rule="evenodd"/></svg>\n      <span class="zammad-chat-welcome-text">');
    
      __out.push(this.invitationPhrase);
    
      __out.push('</span>\n    </div>\n  </div>\n  <div class="zammad-chat-body"></div>\n  <form class="zammad-chat-controls">\n    <textarea class="zammad-chat-input" rows="1" placeholder="');
    
      __out.push(this.T('Compose your message...'));
    
      __out.push('"></textarea>\n    <button type="submit" class="zammad-chat-send">');
    
      __out.push(this.T('Send'));
    
      __out.push('</button>\n  </form>\n</div>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["loader"] = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-modal">\n  <span class="zammad-chat-loading-animation">\n    <span class="zammad-chat-loading-circle"></span>\n    <span class="zammad-chat-loading-circle"></span>\n    <span class="zammad-chat-loading-circle"></span>\n  </span>\n  <span class="zammad-chat-modal-text">');
    
      __out.push(__sanitize(this.T('Connecting')));
    
      __out.push('</span>\n</div>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["message"] = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-message zammad-chat-message--');
    
      __out.push(__sanitize(this.from));
    
      __out.push('">\n  <span class="zammad-chat-message-body">');
    
      __out.push(this.message);
    
      __out.push('</span>\n</div>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["status"] = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-status"><strong>');
    
      __out.push(__sanitize(this.label));
    
      __out.push('</strong> ');
    
      __out.push(__sanitize(this.time));
    
      __out.push('</div>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["typingIndicator"] = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-message zammad-chat-message--typing zammad-chat-message--agent">\n  <span class="zammad-chat-message-body">\n    <span class="zammad-chat-loading-animation">\n      <span class="zammad-chat-loading-circle"></span>\n      <span class="zammad-chat-loading-circle"></span>\n      <span class="zammad-chat-loading-circle"></span>\n    </span>\n  </span>\n</div>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["waiting"] = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-modal">\n  <div class="zammad-chat-modal-text">\n    <span class="zammad-chat-loading-animation">\n      <span class="zammad-chat-loading-circle"></span>\n      <span class="zammad-chat-loading-circle"></span>\n      <span class="zammad-chat-loading-circle"></span>\n    </span>\n    ');
    
      __out.push(this.T('All colleges are busy.'));
    
      __out.push('<br>\n    ');
    
      __out.push(this.T('You are on waiting list position <strong>%s</strong>.', this.position));
    
      __out.push('\n  </div>\n</div>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
