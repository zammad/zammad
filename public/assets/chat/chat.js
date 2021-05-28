if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["agent"] = function(__obj) {
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
    
      __out.push('</span>\n</span>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["chat"] = function(__obj) {
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
      __out.push('<div class="zammad-chat');
    
      if (this.flat) {
        __out.push(__sanitize(' zammad-chat--flat'));
      }
    
      __out.push('"');
    
      if (this.fontSize) {
        __out.push(__sanitize(" style='font-size: " + this.fontSize + "'"));
      }
    
      __out.push('>\n  <div class="zammad-chat-header js-chat-open"');
    
      if (this.background) {
        __out.push(__sanitize(" style='background: " + this.background + "'"));
      }
    
      __out.push('>\n    <div class="zammad-chat-header-controls js-chat-toggle">\n      <span class="zammad-chat-agent-status zammad-chat-is-hidden js-chat-status" data-status="online"></span>\n      <span class="zammad-chat-header-icon">\n        <svg class="zammad-chat-header-icon-open" width="13" height="7" viewBox="0 0 13 7"><path d="M10.807 7l1.4-1.428-5-4.9L6.5-.02l-.7.7-4.9 4.9 1.414 1.413L6.5 2.886 10.807 7z" fill-rule="evenodd"/></svg>\n        <svg class="zammad-chat-header-icon-close" width="13" height="13" viewBox="0 0 13 13"><path d="m2.241.12l-2.121 2.121 4.243 4.243-4.243 4.243 2.121 2.121 4.243-4.243 4.243 4.243 2.121-2.121-4.243-4.243 4.243-4.243-2.121-2.121-4.243 4.243-4.243-4.243" fill-rule="evenodd"/></svg>\n      </span>\n    </div>\n    <div class="zammad-chat-agent zammad-chat-is-hidden">\n    </div>\n    <div class="zammad-chat-welcome">\n      <svg class="zammad-chat-icon" viewBox="0 0 24 24" width="24" height="24"><path d="M2 5C2 4 3 3 4 3h16c1 0 2 1 2 2v10C22 16 21 17 20 17H4C3 17 2 16 2 15V5zM12 17l6 4v-4h-6z"/></svg>\n      <span class="zammad-chat-welcome-text">');
    
      __out.push(this.T(this.title));
    
      __out.push('</span>\n    </div>\n  </div>\n  <div class="zammad-chat-modal"></div>\n  <div class="zammad-scroll-hint is-hidden">\n    <svg class="zammad-scroll-hint-icon" width="20" height="18" viewBox="0 0 20 18"><path d="M0,2.00585866 C0,0.898053512 0.898212381,0 1.99079514,0 L18.0092049,0 C19.1086907,0 20,0.897060126 20,2.00585866 L20,11.9941413 C20,13.1019465 19.1017876,14 18.0092049,14 L1.99079514,14 C0.891309342,14 0,13.1029399 0,11.9941413 L0,2.00585866 Z M10,14 L16,18 L16,14 L10,14 Z" fill-rule="evenodd"/></svg>\n    ');
    
      __out.push(this.T(this.scrollHint));
    
      __out.push('\n  </div>\n  <div class="zammad-chat-body"></div>\n  <form class="zammad-chat-controls">\n    <div class="zammad-chat-input" rows="1" placeholder="');
    
      __out.push(this.T('Compose your message...'));
    
      __out.push('" contenteditable="true"></div>\n    <button type="submit" class="zammad-chat-button zammad-chat-send"');
    
      if (this.background) {
        __out.push(__sanitize(" style='background: " + this.background + "'"));
      }
    
      __out.push('>');
    
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
window.zammadChatTemplates["customer_timeout"] = function(__obj) {
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
      __out.push('<div class="zammad-chat-modal-text">\n  ');
    
      if (this.agent) {
        __out.push('\n    ');
        __out.push(this.T('Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.', this.delay, this.agent));
        __out.push('\n  ');
      } else {
        __out.push('\n    ');
        __out.push(this.T('Since you didn\'t respond in the last %s minutes your conversation got closed.', this.delay));
        __out.push('\n  ');
      }
    
      __out.push('\n  <br>\n  <div class="zammad-chat-button js-restart"');
    
      if (this.background) {
        __out.push(__sanitize(" style='background: " + this.background + "'"));
      }
    
      __out.push('>');
    
      __out.push(this.T('Start new conversation'));
    
      __out.push('</div>\n</div>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  slice = [].slice,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

(function($, window) {
  var Base, Io, Log, Timeout, ZammadChat, myScript, scriptHost, scriptProtocol, scripts;
  scripts = document.getElementsByTagName('script');
  myScript = scripts[scripts.length - 1];
  scriptProtocol = window.location.protocol.replace(':', '');
  if (myScript && myScript.src) {
    scriptHost = myScript.src.match('.*://([^:/]*).*')[1];
    scriptProtocol = myScript.src.match('(.*)://[^:/]*.*')[1];
  }
  Base = (function() {
    Base.prototype.defaults = {
      debug: false
    };

    function Base(options) {
      this.options = $.extend({}, this.defaults, options);
      this.log = new Log({
        debug: this.options.debug,
        logPrefix: this.options.logPrefix || this.logPrefix
      });
    }

    return Base;

  })();
  Log = (function() {
    Log.prototype.defaults = {
      debug: false
    };

    function Log(options) {
      this.log = bind(this.log, this);
      this.error = bind(this.error, this);
      this.notice = bind(this.notice, this);
      this.debug = bind(this.debug, this);
      this.options = $.extend({}, this.defaults, options);
    }

    Log.prototype.debug = function() {
      var items;
      items = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      if (!this.options.debug) {
        return;
      }
      return this.log('debug', items);
    };

    Log.prototype.notice = function() {
      var items;
      items = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return this.log('notice', items);
    };

    Log.prototype.error = function() {
      var items;
      items = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return this.log('error', items);
    };

    Log.prototype.log = function(level, items) {
      var item, j, len, logString;
      items.unshift('||');
      items.unshift(level);
      items.unshift(this.options.logPrefix);
      console.log.apply(console, items);
      if (!this.options.debug) {
        return;
      }
      logString = '';
      for (j = 0, len = items.length; j < len; j++) {
        item = items[j];
        logString += ' ';
        if (typeof item === 'object') {
          logString += JSON.stringify(item);
        } else if (item && item.toString) {
          logString += item.toString();
        } else {
          logString += item;
        }
      }
      return $('.js-chatLogDisplay').prepend('<div>' + logString + '</div>');
    };

    return Log;

  })();
  Timeout = (function(superClass) {
    extend(Timeout, superClass);

    Timeout.prototype.timeoutStartedAt = null;

    Timeout.prototype.logPrefix = 'timeout';

    Timeout.prototype.defaults = {
      debug: false,
      timeout: 4,
      timeoutIntervallCheck: 0.5
    };

    function Timeout(options) {
      this.stop = bind(this.stop, this);
      this.start = bind(this.start, this);
      Timeout.__super__.constructor.call(this, options);
    }

    Timeout.prototype.start = function() {
      var check, timeoutStartedAt;
      this.stop();
      timeoutStartedAt = new Date;
      check = (function(_this) {
        return function() {
          var timeLeft;
          timeLeft = new Date - new Date(timeoutStartedAt.getTime() + _this.options.timeout * 1000 * 60);
          _this.log.debug("Timeout check for " + _this.options.timeout + " minutes (left " + (timeLeft / 1000) + " sec.)");
          if (timeLeft < 0) {
            return;
          }
          _this.stop();
          return _this.options.callback();
        };
      })(this);
      this.log.debug("Start timeout in " + this.options.timeout + " minutes");
      return this.intervallId = setInterval(check, this.options.timeoutIntervallCheck * 1000 * 60);
    };

    Timeout.prototype.stop = function() {
      if (!this.intervallId) {
        return;
      }
      this.log.debug("Stop timeout of " + this.options.timeout + " minutes");
      return clearInterval(this.intervallId);
    };

    return Timeout;

  })(Base);
  Io = (function(superClass) {
    extend(Io, superClass);

    Io.prototype.logPrefix = 'io';

    function Io(options) {
      this.ping = bind(this.ping, this);
      this.send = bind(this.send, this);
      this.reconnect = bind(this.reconnect, this);
      this.close = bind(this.close, this);
      this.connect = bind(this.connect, this);
      this.set = bind(this.set, this);
      Io.__super__.constructor.call(this, options);
    }

    Io.prototype.set = function(params) {
      var key, results, value;
      results = [];
      for (key in params) {
        value = params[key];
        results.push(this.options[key] = value);
      }
      return results;
    };

    Io.prototype.connect = function() {
      this.log.debug("Connecting to " + this.options.host);
      this.ws = new window.WebSocket("" + this.options.host);
      this.ws.onopen = (function(_this) {
        return function(e) {
          _this.log.debug('onOpen', e);
          _this.options.onOpen(e);
          return _this.ping();
        };
      })(this);
      this.ws.onmessage = (function(_this) {
        return function(e) {
          var j, len, pipe, pipes;
          pipes = JSON.parse(e.data);
          _this.log.debug('onMessage', e.data);
          for (j = 0, len = pipes.length; j < len; j++) {
            pipe = pipes[j];
            if (pipe.event === 'pong') {
              _this.ping();
            }
          }
          if (_this.options.onMessage) {
            return _this.options.onMessage(pipes);
          }
        };
      })(this);
      this.ws.onclose = (function(_this) {
        return function(e) {
          _this.log.debug('close websocket connection', e);
          if (_this.pingDelayId) {
            clearTimeout(_this.pingDelayId);
          }
          if (_this.manualClose) {
            _this.log.debug('manual close, onClose callback');
            _this.manualClose = false;
            if (_this.options.onClose) {
              return _this.options.onClose(e);
            }
          } else {
            _this.log.debug('error close, onError callback');
            if (_this.options.onError) {
              return _this.options.onError('Connection lost...');
            }
          }
        };
      })(this);
      return this.ws.onerror = (function(_this) {
        return function(e) {
          _this.log.debug('onError', e);
          if (_this.options.onError) {
            return _this.options.onError(e);
          }
        };
      })(this);
    };

    Io.prototype.close = function() {
      this.log.debug('close websocket manually');
      this.manualClose = true;
      return this.ws.close();
    };

    Io.prototype.reconnect = function() {
      this.log.debug('reconnect');
      this.close();
      return this.connect();
    };

    Io.prototype.send = function(event, data) {
      var msg;
      if (data == null) {
        data = {};
      }
      this.log.debug('send', event, data);
      msg = JSON.stringify({
        event: event,
        data: data
      });
      return this.ws.send(msg);
    };

    Io.prototype.ping = function() {
      var localPing;
      localPing = (function(_this) {
        return function() {
          return _this.send('ping');
        };
      })(this);
      return this.pingDelayId = setTimeout(localPing, 29000);
    };

    return Io;

  })(Base);
  ZammadChat = (function(superClass) {
    extend(ZammadChat, superClass);

    ZammadChat.prototype.defaults = {
      chatId: void 0,
      show: true,
      target: $('body'),
      host: '',
      debug: false,
      flat: false,
      lang: void 0,
      cssAutoload: true,
      cssUrl: void 0,
      fontSize: void 0,
      buttonClass: 'open-zammad-chat',
      inactiveClass: 'is-inactive',
      title: '<strong>Chat</strong> with us!',
      scrollHint: 'Scroll down to see new messages',
      idleTimeout: 6,
      idleTimeoutIntervallCheck: 0.5,
      inactiveTimeout: 8,
      inactiveTimeoutIntervallCheck: 0.5,
      waitingListTimeout: 4,
      waitingListTimeoutIntervallCheck: 0.5,
      onReady: void 0,
      onCloseAnimationEnd: void 0,
      onError: void 0,
      onOpenAnimationEnd: void 0,
      onConnectionReestablished: void 0,
      onSessionClosed: void 0,
      onConnectionEstablished: void 0,
      onCssLoaded: void 0
    };

    ZammadChat.prototype.logPrefix = 'chat';

    ZammadChat.prototype._messageCount = 0;

    ZammadChat.prototype.isOpen = false;

    ZammadChat.prototype.blinkOnlineInterval = null;

    ZammadChat.prototype.stopBlinOnlineStateTimeout = null;

    ZammadChat.prototype.showTimeEveryXMinutes = 2;

    ZammadChat.prototype.lastTimestamp = null;

    ZammadChat.prototype.lastAddedType = null;

    ZammadChat.prototype.inputTimeout = null;

    ZammadChat.prototype.isTyping = false;

    ZammadChat.prototype.state = 'offline';

    ZammadChat.prototype.initialQueueDelay = 10000;

    ZammadChat.prototype.translations = {
      'da': {
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> med os!',
        'Scroll down to see new messages': 'Scroll ned for at se nye beskeder',
        'Online': 'Online',
        'Offline': 'Offline',
        'Connecting': 'Forbinder',
        'Connection re-established': 'Forbindelse genoprettet',
        'Today': 'I dag',
        'Send': 'Send',
        'Chat closed by %s': 'Chat lukket af %s',
        'Compose your message...': 'Skriv en besked...',
        'All colleagues are busy.': 'Alle kollegaer er optaget.',
        'You are on waiting list position <strong>%s</strong>.': 'Du er i venteliste som nummer <strong>%s</strong>.',
        'Start new conversation': 'Start en ny samtale',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Da du ikke har svaret i de sidste %s minutter er din samtale med <strong>%s</strong> blevet lukket.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Da du ikke har svaret i de sidste %s minutter er din samtale blevet lukket.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Vi beklager, det tager længere end forventet at få en ledig plads. Prøv venligst igen senere eller send os en e-mail. På forhånd tak!'
      },
      'de': {
        '<strong>Chat</strong> with us!': '<strong>Chatte</strong> mit uns!',
        'Scroll down to see new messages': 'Scrolle nach unten um neue Nachrichten zu sehen',
        'Online': 'Online',
        'Offline': 'Offline',
        'Connecting': 'Verbinden',
        'Connection re-established': 'Verbindung wiederhergestellt',
        'Today': 'Heute',
        'Send': 'Senden',
        'Chat closed by %s': 'Chat beendet von %s',
        'Compose your message...': 'Ihre Nachricht...',
        'All colleagues are busy.': 'Alle Kollegen sind belegt.',
        'You are on waiting list position <strong>%s</strong>.': 'Sie sind in der Warteliste an der Position <strong>%s</strong>.',
        'Start new conversation': 'Neue Konversation starten',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Da Sie in den letzten %s Minuten nichts geschrieben haben wurde Ihre Konversation mit <strong>%s</strong> geschlossen.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Da Sie in den letzten %s Minuten nichts geschrieben haben wurde Ihre Konversation geschlossen.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Es tut uns leid, es dauert länger als erwartet, um einen freien Platz zu erhalten. Bitte versuchen Sie es zu einem späteren Zeitpunkt noch einmal oder schicken Sie uns eine E-Mail. Vielen Dank!'
      },
      'es': {
        '<strong>Chat</strong> with us!': '<strong>Chatee</strong> con nosotros!',
        'Scroll down to see new messages': 'Haga scroll hacia abajo para ver nuevos mensajes',
        'Online': 'En linea',
        'Offline': 'Desconectado',
        'Connecting': 'Conectando',
        'Connection re-established': 'Conexión restablecida',
        'Today': 'Hoy',
        'Send': 'Enviar',
        'Chat closed by %s': 'Chat cerrado por %s',
        'Compose your message...': 'Escriba su mensaje...',
        'All colleagues are busy.': 'Todos los agentes están ocupados.',
        'You are on waiting list position <strong>%s</strong>.': 'Usted está en la posición <strong>%s</strong> de la lista de espera.',
        'Start new conversation': 'Iniciar nueva conversación',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Puesto que usted no respondió en los últimos %s minutos su conversación con <strong>%s</strong> se ha cerrado.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Puesto que usted no respondió en los últimos %s minutos su conversación se ha cerrado.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Lo sentimos, se tarda más tiempo de lo esperado para ser atendido por un agente. Inténtelo de nuevo más tarde o envíenos un correo electrónico. ¡Gracias!'
      },
      'fi': {
        '<strong>Chat</strong> with us!': '<strong>Keskustele</strong> kanssamme!',
        'Scroll down to see new messages': 'Rullaa alas nähdäksesi uudet viestit',
        'Online': 'Paikalla',
        'Offline': 'Poissa',
        'Connecting': 'Yhdistetään',
        'Connection re-established': 'Yhteys muodostettu uudelleen',
        'Today': 'Tänään',
        'Send': 'Lähetä',
        'Chat closed by %s': '%s sulki keskustelun',
        'Compose your message...': 'Luo viestisi...',
        'All colleagues are busy.': 'Kaikki kollegat ovat varattuja.',
        'You are on waiting list position <strong>%s</strong>.': 'Olet odotuslistalla sijalla <strong>%s</strong>.',
        'Start new conversation': 'Aloita uusi keskustelu',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Koska et vastannut viimeiseen %s minuuttiin, keskustelusi <strong>%s</strong> kanssa suljettiin.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Koska et vastannut viimeiseen %s minuuttiin, keskustelusi suljettiin.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Olemme pahoillamme, tyhjän paikan vapautumisessa kestää odotettua pidempään. Ole hyvä ja yritä myöhemmin uudestaan tai lähetä meille sähköpostia. Kiitos!'
      },
      'fr': {
        '<strong>Chat</strong> with us!': '<strong>Chattez</strong> avec nous!',
        'Scroll down to see new messages': 'Faites défiler pour lire les nouveaux messages',
        'Online': 'En-ligne',
        'Offline': 'Hors-ligne',
        'Connecting': 'Connexion en cours',
        'Connection re-established': 'Connexion rétablie',
        'Today': 'Aujourdhui',
        'Send': 'Envoyer',
        'Chat closed by %s': 'Chat fermé par %s',
        'Compose your message...': 'Composez votre message...',
        'All colleagues are busy.': 'Tous les collaborateurs sont occupés actuellement.',
        'You are on waiting list position <strong>%s</strong>.': 'Vous êtes actuellement en position <strong>%s</strong> dans la file d\'attente.',
        'Start new conversation': 'Démarrer une nouvelle conversation',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Si vous ne répondez pas dans les <strong>%s</strong> minutes, votre conversation avec %s sera fermée.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Si vous ne répondez pas dans les %s minutes, votre conversation va être fermée.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Nous sommes désolés, il faut plus de temps que prévu pour obtenir un emplacement vide. Veuillez réessayer ultérieurement ou nous envoyer un courriel. Nous vous remercions!'
      },
      'he': {
        '<strong>Chat</strong> with us!': '<strong>שוחח</strong>איתנו!',
        'Scroll down to see new messages': 'גלול מטה כדי לראות הודעות חדשות',
        'Online': 'מחובר',
        'Offline': 'מנותק',
        'Connecting': 'מתחבר',
        'Connection re-established': 'החיבור שוחזר',
        'Today': 'היום',
        'Send': 'שלח',
        'Chat closed by %s': 'הצאט נסגר ע"י %s',
        'Compose your message...': 'כתוב את ההודעה שלך ...',
        'All colleagues are busy.': 'כל הנציגים תפוסים',
        'You are on waiting list position <strong>%s</strong>.': 'מיקומך בתור <strong>%s</strong>.',
        'Start new conversation': 'התחל שיחה חדשה',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'מכיוון שלא הגבת במהלך %s דקות השיחה שלך עם <strong>%s</strong> נסגרה.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'מכיוון שלא הגבת במהלך %s הדקות האחרונות השיחה שלך נסגרה.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'מצטערים, הזמן לקבלת נציג ארוך מהרגיל. נסה שוב מאוחר יותר או שלח לנו דוא"ל. תודה!'
      },
      'hu': {
        '<strong>Chat</strong> with us!': '<strong>Chatelj</strong> velünk!',
        'Scroll down to see new messages': 'Görgess lejjebb az újabb üzenetekért',
        'Online': 'Online',
        'Offline': 'Offline',
        'Connecting': 'Csatlakozás',
        'Connection re-established': 'Újracsatlakozás',
        'Today': 'Ma',
        'Send': 'Küldés',
        'Chat closed by %s': 'A beszélgetést lezárta %s',
        'Compose your message...': 'Írj üzenetet...',
        'All colleagues are busy.': 'Jelenleg minden kollégánk elfoglalt.',
        'You are on waiting list position <strong>%s</strong>.': 'A várólistán a <strong>%s</strong>. pozícióban várakozol.',
        'Start new conversation': 'Új beszélgetés indítása',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Mivel %s perce nem érkezett újabb üzenet, ezért a <strong>%s</strong> kollégával folytatott beszéletést lezártuk.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Mivel %s perce nem érkezett válasz, a beszélgetés lezárult.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Sajnáljuk, de a várakozási idő hosszabb a szokásosnál. Kérlek próbáld újra, vagy írd meg kérdésed emailben. Köszönjük!'
      },
      'nl': {
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> met ons!',
        'Scroll down to see new messages': 'Scrol naar beneden om nieuwe berichten te zien',
        'Online': 'Online',
        'Offline': 'Offline',
        'Connecting': 'Verbinden',
        'Connection re-established': 'Verbinding herstelt',
        'Today': 'Vandaag',
        'Send': 'Verzenden',
        'Chat closed by %s': 'Chat gesloten door %s',
        'Compose your message...': 'Typ uw bericht...',
        'All colleagues are busy.': 'Alle medewerkers zijn bezet.',
        'You are on waiting list position <strong>%s</strong>.': 'U bent <strong>%s</strong> in de wachtrij.',
        'Start new conversation': 'Nieuwe conversatie starten',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Omdat u in de laatste %s minuten niets geschreven heeft wordt de conversatie met <strong>%s</strong> gesloten.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Omdat u in de laatste %s minuten niets geschreven heeft is de conversatie gesloten.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Het spijt ons, het duurt langer dan verwacht om te antwoorden. Alstublieft probeer het later nogmaals of stuur ons een email. Hartelijk dank!'
      },
      'it': {
        '<strong>Chat</strong> with us!': '<strong>Chatta</strong> con noi!',
        'Scroll down to see new messages': 'Scorri verso il basso per vedere i nuovi messaggi',
        'Online': 'Online',
        'Offline': 'Offline',
        'Connecting': 'Collegamento in corso',
        'Connection re-established': 'Collegamento ristabilito',
        'Today': 'Oggi',
        'Send': 'Invio',
        'Chat closed by %s': 'Chat chiusa da %s',
        'Compose your message...': 'Componi il tuo messaggio...',
        'All colleagues are busy.': 'Tutti gli operatori sono occupati.',
        'You are on waiting list position <strong>%s</strong>.': 'Sei in posizione <strong>%s</strong> nella lista d\'attesa.',
        'Start new conversation': 'Avvia una nuova chat',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Dal momento che non hai risposto negli ultimi %s minuti la tua chat con <strong>%s</strong> è stata chiusa.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Dal momento che non hai risposto negli ultimi %s minuti la tua chat è stata chiusa.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Ci dispiace, ci vuole più tempo del previsto per arrivare al tuo turno. Per favore riprova più tardi o inviaci un\'email. Grazie!'
      },
      'pl': {
        '<strong>Chat</strong> with us!': '<strong>Czatuj</strong> z nami!',
        'Scroll down to see new messages': 'Przewiń w dół, aby wyświetlić nowe wiadomości',
        'Online': 'Online',
        'Offline': 'Offline',
        'Connecting': 'Łączenie',
        'Connection re-established': 'Ponowne nawiązanie połączenia',
        'Today': 'dzisiejszy',
        'Send': 'Wyślij',
        'Chat closed by %s': 'Czat zamknięty przez %s',
        'Compose your message...': 'Utwórz swoją wiadomość...',
        'All colleagues are busy.': 'Wszyscy koledzy są zajęci.',
        'You are on waiting list position <strong>%s</strong>.': 'Na liście oczekujących znajduje się pozycja <strong>%s</strong>.',
        'Start new conversation': 'Rozpoczęcie nowej konwersacji',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Ponieważ w ciągu ostatnich %s minut nie odpowiedziałeś, Twoja rozmowa z <strong>%s</strong> została zamknięta.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Ponieważ nie odpowiedziałeś w ciągu ostatnich %s minut, Twoja rozmowa została zamknięta.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Przykro nam, ale to trwa dłużej niż się spodziewamy. Spróbuj ponownie później lub wyślij nam wiadomość e-mail. Dziękuję!'
      },
      'pt-br': {
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> fale conosco!',
        'Scroll down to see new messages': 'Role para baixo, para ver nosvas mensagens',
        'Online': 'Online',
        'Offline': 'Desconectado',
        'Connecting': 'Conectando',
        'Connection re-established': 'Conexão restabelecida',
        'Today': 'Hoje',
        'Send': 'Enviar',
        'Chat closed by %s': 'Chat encerrado por %s',
        'Compose your message...': 'Escreva sua mensagem...',
        'All colleagues are busy.': 'Todos os agentes estão ocupados.',
        'You are on waiting list position <strong>%s</strong>.': 'Você está na posição <strong>%s</strong> na fila de espera.',
        'Start new conversation': 'Iniciar uma nova conversa',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Como você não respondeu nos últimos %s minutos sua conversa com <strong>%s</strong> foi encerrada.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Como você não respondeu nos últimos %s minutos sua conversa foi encerrada.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Desculpe, mas o tempo de espera por um agente foi excedido. Tente novamente mais tarde ou nós envie um email. Obrigado'
      },
      'zh-cn': {
        '<strong>Chat</strong> with us!': '发起<strong>即时对话</strong>!',
        'Scroll down to see new messages': '向下滚动以查看新消息',
        'Online': '在线',
        'Offline': '离线',
        'Connecting': '连接中',
        'Connection re-established': '正在重新建立连接',
        'Today': '今天',
        'Send': '发送',
        'Chat closed by %s': 'Chat closed by %s',
        'Compose your message...': '正在输入信息...',
        'All colleagues are busy.': '所有工作人员都在忙碌中.',
        'You are on waiting list position <strong>%s</strong>.': '您目前的等候位置是第 <strong>%s</strong> 位.',
        'Start new conversation': '开始新的会话',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': '由于您超过 %s 分钟没有回复, 您与 <strong>%s</strong> 的会话已被关闭.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': '由于您超过 %s 分钟没有任何回复, 该对话已被关闭.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': '非常抱歉, 目前需要等候更长的时间才能接入对话, 请稍后重试或向我们发送电子邮件. 谢谢!'
      },
      'zh-tw': {
        '<strong>Chat</strong> with us!': '開始<strong>即時對话</strong>!',
        'Scroll down to see new messages': '向下滑動以查看新訊息',
        'Online': '線上',
        'Offline': '离线',
        'Connecting': '連線中',
        'Connection re-established': '正在重新建立連線中',
        'Today': '今天',
        'Send': '發送',
        'Chat closed by %s': 'Chat closed by %s',
        'Compose your message...': '正在輸入訊息...',
        'All colleagues are busy.': '所有服務人員都在忙碌中.',
        'You are on waiting list position <strong>%s</strong>.': '你目前的等候位置是第 <strong>%s</strong> 順位.',
        'Start new conversation': '開始新的對話',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': '由於你超過 %s 分鐘沒有回應, 你與 <strong>%s</strong> 的對話已被關閉.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': '由於你超過 %s 分鐘沒有任何回應, 該對話已被關閉.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': '非常抱歉, 當前需要等候更長的時間方可排入對話程序, 請稍後重試或向我們寄送電子郵件. 謝謝!'
      },
      'ru': {
        '<strong>Chat</strong> with us!': 'Напишите нам!',
        'Scroll down to see new messages': 'Прокрутите, чтобы увидеть новые сообщения',
        'Online': 'Онлайн',
        'Offline': 'Оффлайн',
        'Connecting': 'Подключение',
        'Connection re-established': 'Подключение восстановлено',
        'Today': 'Сегодня',
        'Send': 'Отправить',
        'Chat closed by %s': '%s закрыл чат',
        'Compose your message...': 'Напишите сообщение...',
        'All colleagues are busy.': 'Все сотрудники заняты',
        'You are on waiting list position %s.': 'Вы в списке ожидания под номером %s',
        'Start new conversation': 'Начать новую переписку.',
        'Since you didn\'t respond in the last %s minutes your conversation with %s got closed.': 'Поскольку вы не отвечали в течение последних %s минут, ваш разговор с %s был закрыт.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Поскольку вы не отвечали в течение последних %s минут, ваш разговор был закрыт.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'К сожалению, ожидание свободного места требует больше времени. Повторите попытку позже или отправьте нам электронное письмо. Спасибо!'
      },
      'sv': {
        '<strong>Chat</strong> with us!': '<strong>Chatta</strong> med oss!',
        'Scroll down to see new messages': 'Rulla ner för att se nya meddelanden',
        'Online': 'Online',
        'Offline': 'Offline',
        'Connecting': 'Ansluter',
        'Connection re-established': 'Anslutningen återupprättas',
        'Today': 'I dag',
        'Send': 'Skicka',
        'Chat closed by %s': 'Chatt stängd av %s',
        'Compose your message...': 'Skriv ditt meddelande...',
        'All colleagues are busy.': 'Alla kollegor är upptagna.',
        'You are on waiting list position <strong>%s</strong>.': 'Du är på väntelistan som position <strong>%s</strong>.',
        'Start new conversation': 'Starta ny konversation',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Eftersom du inte svarat inom %s minuterna i din konversation med <strong>%s</strong> så stängdes chatten.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Då du inte svarat inom de senaste %s minuterna så avslutades din chatt.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Vi är ledsna, det tar längre tid som förväntat att få en ledig plats. Försök igen senare eller skicka ett e-postmeddelande till oss. Tack!'
      },
      'no': {
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> med oss!',
        'Scroll down to see new messages': 'Bla ned for å se nye meldinger',
        'Online': 'Pålogget',
        'Offline': 'Avlogget',
        'Connecting': 'Koble til',
        'Connection re-established': 'Tilkoblingen er gjenopprettet',
        'Today': 'I dag',
        'Send': 'Send',
        'Chat closed by %s': 'Chat avsluttes om %s',
        'Compose your message...': 'Skriv din melding...',
        'All colleagues are busy.': 'Alle våre kolleger er for øyeblikket opptatt.',
        'You are on waiting list position <strong>%s</strong>.': 'Du står nå i kø og er nr. <strong>%s</strong> på ventelisten.',
        'Start new conversation': 'Start en ny samtale',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Ettersom du ikke har respondert i løpet av de siste %s minuttene av samtalen, vil samtalen med  <strong>%s</strong> nå avsluttes.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Ettersom du ikke har respondert i løpet av de siste %s minuttene, har samtalen nå blitt avsluttet.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Vi beklager, men det tar lengre tid enn vanlig å få en ledig plass i vår chat. Vennligst prøv igjen på et senere tidspunkt eller send oss en e-post. Tusen takk!'
      },
      'nb': {
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> med oss!',
        'Scroll down to see new messages': 'Bla ned for å se nye meldinger',
        'Online': 'Pålogget',
        'Offline': 'Avlogget',
        'Connecting': 'Koble til',
        'Connection re-established': 'Tilkoblingen er gjenopprettet',
        'Today': 'I dag',
        'Send': 'Send',
        'Chat closed by %s': 'Chat avsluttes om %s',
        'Compose your message...': 'Skriv din melding...',
        'All colleagues are busy.': 'Alle våre kolleger er for øyeblikket opptatt.',
        'You are on waiting list position <strong>%s</strong>.': 'Du står nå i kø og er nr. <strong>%s</strong> på ventelisten.',
        'Start new conversation': 'Start en ny samtale',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Ettersom du ikke har respondert i løpet av de siste %s minuttene av samtalen, vil samtalen med  <strong>%s</strong> nå avsluttes.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Ettersom du ikke har respondert i løpet av de siste %s minuttene, har samtalen nå blitt avsluttet.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Vi beklager, men det tar lengre tid enn vanlig å få en ledig plass i vår chat. Vennligst prøv igjen på et senere tidspunkt eller send oss en e-post. Tusen takk!'
      },
      'el': {
        '<strong>Chat</strong> with us!': '<strong>Επικοινωνήστε</strong> μαζί μας!',
        'Scroll down to see new messages': 'Μεταβείτε κάτω για να δείτε τα νέα μηνύματα',
        'Online': 'Σε σύνδεση',
        'Offline': 'Αποσυνδεμένος',
        'Connecting': 'Σύνδεση',
        'Connection re-established': 'Η σύνδεση αποκαταστάθηκε',
        'Today': 'Σήμερα',
        'Send': 'Αποστολή',
        'Chat closed by %s': 'Η συνομιλία έκλεισε από τον/την %s',
        'Compose your message...': 'Γράψτε το μήνυμα σας...',
        'All colleagues are busy.': 'Όλοι οι συνάδελφοι μας είναι απασχολημένοι.',
        'You are on waiting list position <strong>%s</strong>.': 'Βρίσκεστε σε λίστα αναμονής στη θέση <strong>%s</strong>.',
        'Start new conversation': 'Έναρξη νέας συνομιλίας',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Από τη στιγμή που δεν απαντήσατε τα τελευταία %s λεπτά η συνομιλία σας με τον/την <strong>%s</strong> έκλεισε.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Από τη στιγμή που δεν απαντήσατε τα τελευταία %s λεπτά η συνομιλία σας έκλεισε.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Λυπούμαστε που χρειάζεται περισσότερος χρόνος από τον αναμενόμενο για να βρεθεί μία κενή θέση. Παρακαλούμε δοκιμάστε ξανά αργότερα ή στείλτε μας ένα email. Ευχαριστούμε!'
      }
    };

    ZammadChat.prototype.sessionId = void 0;

    ZammadChat.prototype.scrolledToBottom = true;

    ZammadChat.prototype.scrollSnapTolerance = 10;

    ZammadChat.prototype.richTextFormatKey = {
      66: true,
      73: true,
      85: true,
      83: true
    };

    ZammadChat.prototype.T = function() {
      var item, items, j, len, string, translations;
      string = arguments[0], items = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      if (this.options.lang && this.options.lang !== 'en') {
        if (!this.translations[this.options.lang]) {
          this.log.notice("Translation '" + this.options.lang + "' needed!");
        } else {
          translations = this.translations[this.options.lang];
          if (!translations[string]) {
            this.log.notice("Translation needed for '" + string + "'");
          }
          string = translations[string] || string;
        }
      }
      if (items) {
        for (j = 0, len = items.length; j < len; j++) {
          item = items[j];
          string = string.replace(/%s/, item);
        }
      }
      return string;
    };

    ZammadChat.prototype.view = function(name) {
      return (function(_this) {
        return function(options) {
          if (!options) {
            options = {};
          }
          options.T = _this.T;
          options.background = _this.options.background;
          options.flat = _this.options.flat;
          options.fontSize = _this.options.fontSize;
          return window.zammadChatTemplates[name](options);
        };
      })(this);
    };

    function ZammadChat(options) {
      this.removeAttributes = bind(this.removeAttributes, this);
      this.startTimeoutObservers = bind(this.startTimeoutObservers, this);
      this.onCssLoaded = bind(this.onCssLoaded, this);
      this.setAgentOnlineState = bind(this.setAgentOnlineState, this);
      this.onConnectionEstablished = bind(this.onConnectionEstablished, this);
      this.setSessionId = bind(this.setSessionId, this);
      this.onConnectionReestablished = bind(this.onConnectionReestablished, this);
      this.reconnect = bind(this.reconnect, this);
      this.destroy = bind(this.destroy, this);
      this.onScrollHintClick = bind(this.onScrollHintClick, this);
      this.detectScrolledtoBottom = bind(this.detectScrolledtoBottom, this);
      this.onLeaveTemporary = bind(this.onLeaveTemporary, this);
      this.onAgentTypingEnd = bind(this.onAgentTypingEnd, this);
      this.onAgentTypingStart = bind(this.onAgentTypingStart, this);
      this.onQueue = bind(this.onQueue, this);
      this.onQueueScreen = bind(this.onQueueScreen, this);
      this.onWebSocketClose = bind(this.onWebSocketClose, this);
      this.onCloseAnimationEnd = bind(this.onCloseAnimationEnd, this);
      this.close = bind(this.close, this);
      this.toggle = bind(this.toggle, this);
      this.sessionClose = bind(this.sessionClose, this);
      this.onOpenAnimationEnd = bind(this.onOpenAnimationEnd, this);
      this.open = bind(this.open, this);
      this.renderMessage = bind(this.renderMessage, this);
      this.receiveMessage = bind(this.receiveMessage, this);
      this.onSubmit = bind(this.onSubmit, this);
      this.onFocus = bind(this.onFocus, this);
      this.onInput = bind(this.onInput, this);
      this.onReopenSession = bind(this.onReopenSession, this);
      this.onError = bind(this.onError, this);
      this.onWebSocketMessage = bind(this.onWebSocketMessage, this);
      this.send = bind(this.send, this);
      this.checkForEnter = bind(this.checkForEnter, this);
      this.render = bind(this.render, this);
      this.view = bind(this.view, this);
      this.T = bind(this.T, this);
      this.options = $.extend({}, this.defaults, options);
      ZammadChat.__super__.constructor.call(this, this.options);
      this.isFullscreen = window.matchMedia && window.matchMedia('(max-width: 768px)').matches;
      this.scrollRoot = $(this.getScrollRoot());
      if (!$) {
        this.state = 'unsupported';
        this.log.notice('Chat: no jquery found!');
        return;
      }
      if (!window.WebSocket || !sessionStorage) {
        this.state = 'unsupported';
        this.log.notice('Chat: Browser not supported!');
        return;
      }
      if (!this.options.chatId) {
        this.state = 'unsupported';
        this.log.error('Chat: need chatId as option!');
        return;
      }
      if (!this.options.lang) {
        this.options.lang = $('html').attr('lang');
      }
      if (this.options.lang) {
        if (!this.translations[this.options.lang]) {
          this.log.debug("lang: No " + this.options.lang + " found, try first two letters");
          this.options.lang = this.options.lang.replace(/-.+?$/, '');
        }
        this.log.debug("lang: " + this.options.lang);
      }
      if (!this.options.host) {
        this.detectHost();
      }
      this.loadCss();
      this.io = new Io(this.options);
      this.io.set({
        onOpen: this.render,
        onClose: this.onWebSocketClose,
        onMessage: this.onWebSocketMessage,
        onError: this.onError
      });
      this.io.connect();
    }

    ZammadChat.prototype.getScrollRoot = function() {
      var end, html, start;
      if ('scrollingElement' in document) {
        return document.scrollingElement;
      }
      html = document.documentElement;
      start = html.scrollTop;
      html.scrollTop = start + 1;
      end = html.scrollTop;
      html.scrollTop = start;
      if (end > start) {
        return html;
      } else {
        return document.body;
      }
    };

    ZammadChat.prototype.render = function() {
      if (!this.el || !$('.zammad-chat').get(0)) {
        this.renderBase();
      }
      $("." + this.options.buttonClass).addClass(this.options.inactiveClass);
      this.setAgentOnlineState('online');
      this.log.debug('widget rendered');
      this.startTimeoutObservers();
      this.idleTimeout.start();
      this.sessionId = sessionStorage.getItem('sessionId');
      return this.send('chat_status_customer', {
        session_id: this.sessionId,
        url: window.location.href
      });
    };

    ZammadChat.prototype.renderBase = function() {
      this.el = $(this.view('chat')({
        title: this.options.title,
        scrollHint: this.options.scrollHint
      }));
      this.options.target.append(this.el);
      this.input = this.el.find('.zammad-chat-input');
      this.el.find('.js-chat-open').click(this.open);
      this.el.find('.js-chat-toggle').click(this.toggle);
      this.el.find('.js-chat-status').click(this.stopPropagation);
      this.el.find('.zammad-chat-controls').on('submit', this.onSubmit);
      this.el.find('.zammad-chat-body').on('scroll', this.detectScrolledtoBottom);
      this.el.find('.zammad-scroll-hint').click(this.onScrollHintClick);
      this.input.on({
        keydown: this.checkForEnter,
        input: this.onInput
      });
      this.input.on('keydown', (function(_this) {
        return function(e) {
          var richtTextControl;
          richtTextControl = false;
          if (!e.altKey && !e.ctrlKey && e.metaKey) {
            richtTextControl = true;
          } else if (!e.altKey && e.ctrlKey && !e.metaKey) {
            richtTextControl = true;
          }
          if (richtTextControl && _this.richTextFormatKey[e.keyCode]) {
            e.preventDefault();
            if (e.keyCode === 66) {
              document.execCommand('bold');
              return true;
            }
            if (e.keyCode === 73) {
              document.execCommand('italic');
              return true;
            }
            if (e.keyCode === 85) {
              document.execCommand('underline');
              return true;
            }
            if (e.keyCode === 83) {
              document.execCommand('strikeThrough');
              return true;
            }
          }
        };
      })(this));
      this.input.on('paste', (function(_this) {
        return function(e) {
          var clipboardData, docType, html, htmlTmp, imageFile, imageInserted, item, match, reader, regex, replacementTag, text;
          e.stopPropagation();
          e.preventDefault();
          clipboardData;
          if (e.clipboardData) {
            clipboardData = e.clipboardData;
          } else if (window.clipboardData) {
            clipboardData = window.clipboardData;
          } else if (e.originalEvent.clipboardData) {
            clipboardData = e.originalEvent.clipboardData;
          } else {
            throw 'No clipboardData support';
          }
          imageInserted = false;
          if (clipboardData && clipboardData.items && clipboardData.items[0]) {
            item = clipboardData.items[0];
            if (item.kind === 'file' && (item.type === 'image/png' || item.type === 'image/jpeg')) {
              imageFile = item.getAsFile();
              reader = new FileReader();
              reader.onload = function(e) {
                var img, insert, result;
                result = e.target.result;
                img = document.createElement('img');
                img.src = result;
                insert = function(dataUrl, width, height, isRetina) {
                  if (_this.isRetina()) {
                    width = width / 2;
                    height = height / 2;
                  }
                  result = dataUrl;
                  img = "<img style=\"width: 100%; max-width: " + width + "px;\" src=\"" + result + "\">";
                  return document.execCommand('insertHTML', false, img);
                };
                return _this.resizeImage(img.src, 460, 'auto', 2, 'image/jpeg', 'auto', insert);
              };
              reader.readAsDataURL(imageFile);
              imageInserted = true;
            }
          }
          if (imageInserted) {
            return;
          }
          text = void 0;
          docType = void 0;
          try {
            text = clipboardData.getData('text/html');
            docType = 'html';
            if (!text || text.length === 0) {
              docType = 'text';
              text = clipboardData.getData('text/plain');
            }
            if (!text || text.length === 0) {
              docType = 'text2';
              text = clipboardData.getData('text');
            }
          } catch (error) {
            e = error;
            console.log('Sorry, can\'t insert markup because browser is not supporting it.');
            docType = 'text3';
            text = clipboardData.getData('text');
          }
          if (docType === 'text' || docType === 'text2' || docType === 'text3') {
            text = '<div>' + text.replace(/\n/g, '</div><div>') + '</div>';
            text = text.replace(/<div><\/div>/g, '<div><br></div>');
          }
          console.log('p', docType, text);
          if (docType === 'html') {
            html = $("<div>" + text + "</div>");
            match = false;
            htmlTmp = text;
            regex = new RegExp('<(/w|w)\:[A-Za-z]');
            if (htmlTmp.match(regex)) {
              match = true;
              htmlTmp = htmlTmp.replace(regex, '');
            }
            regex = new RegExp('<(/o|o)\:[A-Za-z]');
            if (htmlTmp.match(regex)) {
              match = true;
              htmlTmp = htmlTmp.replace(regex, '');
            }
            if (match) {
              html = _this.wordFilter(html);
            }
            html = $(html);
            html.contents().each(function() {
              if (this.nodeType === 8) {
                return $(this).remove();
              }
            });
            html.find('a, font, small, time, form, label').replaceWith(function() {
              return $(this).contents();
            });
            replacementTag = 'div';
            html.find('textarea').each(function() {
              var newTag, outer;
              outer = this.outerHTML;
              regex = new RegExp('<' + this.tagName, 'i');
              newTag = outer.replace(regex, '<' + replacementTag);
              regex = new RegExp('</' + this.tagName, 'i');
              newTag = newTag.replace(regex, '</' + replacementTag);
              return $(this).replaceWith(newTag);
            });
            html.find('font, img, svg, input, select, button, style, applet, embed, noframes, canvas, script, frame, iframe, meta, link, title, head, fieldset').remove();
            _this.removeAttributes(html);
            text = html.html();
          }
          if (docType === 'text3') {
            _this.pasteHtmlAtCaret(text);
          } else {
            document.execCommand('insertHTML', false, text);
          }
          return true;
        };
      })(this));
      this.input.on('drop', (function(_this) {
        return function(e) {
          var dataTransfer, file, reader, x, y;
          e.stopPropagation();
          e.preventDefault();
          dataTransfer;
          if (window.dataTransfer) {
            dataTransfer = window.dataTransfer;
          } else if (e.originalEvent.dataTransfer) {
            dataTransfer = e.originalEvent.dataTransfer;
          } else {
            throw 'No clipboardData support';
          }
          x = e.clientX;
          y = e.clientY;
          file = dataTransfer.files[0];
          if (file.type.match('image.*')) {
            reader = new FileReader();
            reader.onload = function(e) {
              var img, insert, result;
              result = e.target.result;
              img = document.createElement('img');
              img.src = result;
              insert = function(dataUrl, width, height, isRetina) {
                var pos, range;
                if (_this.isRetina()) {
                  width = width / 2;
                  height = height / 2;
                }
                result = dataUrl;
                img = $("<img style=\"width: 100%; max-width: " + width + "px;\" src=\"" + result + "\">");
                img = img.get(0);
                if (document.caretPositionFromPoint) {
                  pos = document.caretPositionFromPoint(x, y);
                  range = document.createRange();
                  range.setStart(pos.offsetNode, pos.offset);
                  range.collapse();
                  return range.insertNode(img);
                } else if (document.caretRangeFromPoint) {
                  range = document.caretRangeFromPoint(x, y);
                  return range.insertNode(img);
                } else {
                  return console.log('could not find carat');
                }
              };
              return _this.resizeImage(img.src, 460, 'auto', 2, 'image/jpeg', 'auto', insert);
            };
            return reader.readAsDataURL(file);
          }
        };
      })(this));
      $(window).on('beforeunload', (function(_this) {
        return function() {
          return _this.onLeaveTemporary();
        };
      })(this));
      $(window).bind('hashchange', (function(_this) {
        return function() {
          if (_this.isOpen) {
            if (_this.sessionId) {
              _this.send('chat_session_notice', {
                session_id: _this.sessionId,
                message: window.location.href
              });
            }
            return;
          }
          return _this.idleTimeout.start();
        };
      })(this));
      if (this.isFullscreen) {
        return this.input.on({
          focus: this.onFocus,
          focusout: this.onFocusOut
        });
      }
    };

    ZammadChat.prototype.stopPropagation = function(event) {
      return event.stopPropagation();
    };

    ZammadChat.prototype.checkForEnter = function(event) {
      if (!event.shiftKey && event.keyCode === 13) {
        event.preventDefault();
        return this.sendMessage();
      }
    };

    ZammadChat.prototype.send = function(event, data) {
      if (data == null) {
        data = {};
      }
      data.chat_id = this.options.chatId;
      return this.io.send(event, data);
    };

    ZammadChat.prototype.onWebSocketMessage = function(pipes) {
      var j, len, pipe;
      for (j = 0, len = pipes.length; j < len; j++) {
        pipe = pipes[j];
        this.log.debug('ws:onmessage', pipe);
        switch (pipe.event) {
          case 'chat_error':
            this.log.notice(pipe.data);
            if (pipe.data && pipe.data.state === 'chat_disabled') {
              this.destroy({
                remove: true
              });
            }
            break;
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
            this.onQueueScreen(pipe.data);
            break;
          case 'chat_session_closed':
            this.onSessionClosed(pipe.data);
            break;
          case 'chat_session_left':
            this.onSessionClosed(pipe.data);
            break;
          case 'chat_session_notice':
            this.addStatus(this.T(pipe.data.message));
            break;
          case 'chat_status_customer':
            switch (pipe.data.state) {
              case 'online':
                this.sessionId = void 0;
                if (!this.options.cssAutoload || this.cssLoaded) {
                  this.onReady();
                } else {
                  this.socketReady = true;
                }
                break;
              case 'offline':
                this.onError('Zammad Chat: No agent online');
                break;
              case 'chat_disabled':
                this.onError('Zammad Chat: Chat is disabled');
                break;
              case 'no_seats_available':
                this.onError("Zammad Chat: Too many clients in queue. Clients in queue: " + pipe.data.queue);
                break;
              case 'reconnect':
                this.onReopenSession(pipe.data);
            }
        }
      }
    };

    ZammadChat.prototype.onReady = function() {
      var base;
      this.log.debug('widget ready for use');
      $("." + this.options.buttonClass).click(this.open).removeClass(this.options.inactiveClass);
      if (typeof (base = this.options).onReady === "function") {
        base.onReady();
      }
      if (this.options.show) {
        return this.show();
      }
    };

    ZammadChat.prototype.onError = function(message) {
      var base;
      this.log.debug(message);
      this.addStatus(message);
      $("." + this.options.buttonClass).hide();
      if (this.isOpen) {
        this.disableInput();
        this.destroy({
          remove: false
        });
      } else {
        this.destroy({
          remove: true
        });
      }
      return typeof (base = this.options).onError === "function" ? base.onError(message) : void 0;
    };

    ZammadChat.prototype.onReopenSession = function(data) {
      var j, len, message, ref, unfinishedMessage;
      this.log.debug('old messages', data.session);
      this.inactiveTimeout.start();
      unfinishedMessage = sessionStorage.getItem('unfinished_message');
      if (data.agent) {
        this.onConnectionEstablished(data);
        ref = data.session;
        for (j = 0, len = ref.length; j < len; j++) {
          message = ref[j];
          this.renderMessage({
            message: message.content,
            id: message.id,
            from: message.created_by_id ? 'agent' : 'customer'
          });
        }
        if (unfinishedMessage) {
          this.input.html(unfinishedMessage);
        }
      }
      if (data.position) {
        this.onQueue(data);
      }
      this.show();
      this.open();
      this.scrollToBottom();
      if (unfinishedMessage) {
        return this.input.focus();
      }
    };

    ZammadChat.prototype.onInput = function() {
      this.el.find('.zammad-chat-message--unread').removeClass('zammad-chat-message--unread');
      sessionStorage.setItem('unfinished_message', this.input.html());
      return this.onTyping();
    };

    ZammadChat.prototype.onFocus = function() {
      var keyboardShown;
      $(window).scrollTop(10);
      keyboardShown = $(window).scrollTop() > 0;
      $(window).scrollTop(0);
      if (keyboardShown) {
        return this.log.notice('virtual keyboard shown');
      }
    };

    ZammadChat.prototype.onFocusOut = function() {};

    ZammadChat.prototype.onTyping = function() {
      if (this.isTyping && this.isTyping > new Date(new Date().getTime() - 1500)) {
        return;
      }
      this.isTyping = new Date();
      this.send('chat_session_typing', {
        session_id: this.sessionId
      });
      return this.inactiveTimeout.start();
    };

    ZammadChat.prototype.onSubmit = function(event) {
      event.preventDefault();
      return this.sendMessage();
    };

    ZammadChat.prototype.sendMessage = function() {
      var message, messageElement;
      message = this.input.html();
      if (!message) {
        return;
      }
      this.inactiveTimeout.start();
      sessionStorage.removeItem('unfinished_message');
      messageElement = this.view('message')({
        message: message,
        from: 'customer',
        id: this._messageCount++,
        unreadClass: ''
      });
      this.maybeAddTimestamp();
      if (this.el.find('.zammad-chat-message--typing').get(0)) {
        this.lastAddedType = 'typing-placeholder';
        this.el.find('.zammad-chat-message--typing').before(messageElement);
      } else {
        this.lastAddedType = 'message--customer';
        this.el.find('.zammad-chat-body').append(messageElement);
      }
      this.input.html('');
      this.scrollToBottom();
      return this.send('chat_session_message', {
        content: message,
        id: this._messageCount,
        session_id: this.sessionId
      });
    };

    ZammadChat.prototype.receiveMessage = function(data) {
      this.inactiveTimeout.start();
      this.onAgentTypingEnd();
      this.maybeAddTimestamp();
      this.renderMessage({
        message: data.message.content,
        id: data.id,
        from: 'agent'
      });
      return this.scrollToBottom({
        showHint: true
      });
    };

    ZammadChat.prototype.renderMessage = function(data) {
      this.lastAddedType = "message--" + data.from;
      data.unreadClass = document.hidden ? ' zammad-chat-message--unread' : '';
      return this.el.find('.zammad-chat-body').append(this.view('message')(data));
    };

    ZammadChat.prototype.open = function() {
      var remainerHeight;
      if (this.isOpen) {
        this.log.debug('widget already open, block');
        return;
      }
      this.isOpen = true;
      this.log.debug('open widget');
      this.show();
      if (!this.sessionId) {
        this.showLoader();
      }
      this.el.addClass('zammad-chat-is-open');
      remainerHeight = this.el.height() - this.el.find('.zammad-chat-header').outerHeight();
      this.el.css('bottom', -remainerHeight);
      if (!this.sessionId) {
        this.el.animate({
          bottom: 0
        }, 500, this.onOpenAnimationEnd);
        return this.send('chat_session_init', {
          url: window.location.href
        });
      } else {
        this.el.css('bottom', 0);
        return this.onOpenAnimationEnd();
      }
    };

    ZammadChat.prototype.onOpenAnimationEnd = function() {
      var base;
      this.idleTimeout.stop();
      if (this.isFullscreen) {
        this.disableScrollOnRoot();
      }
      return typeof (base = this.options).onOpenAnimationEnd === "function" ? base.onOpenAnimationEnd() : void 0;
    };

    ZammadChat.prototype.sessionClose = function() {
      this.send('chat_session_close', {
        session_id: this.sessionId
      });
      this.inactiveTimeout.stop();
      this.waitingListTimeout.stop();
      sessionStorage.removeItem('unfinished_message');
      if (this.onInitialQueueDelayId) {
        clearTimeout(this.onInitialQueueDelayId);
      }
      return this.setSessionId(void 0);
    };

    ZammadChat.prototype.toggle = function(event) {
      if (this.isOpen) {
        return this.close(event);
      } else {
        return this.open(event);
      }
    };

    ZammadChat.prototype.close = function(event) {
      var remainerHeight;
      if (!this.isOpen) {
        this.log.debug('can\'t close widget, it\'s not open');
        return;
      }
      if (this.initDelayId) {
        clearTimeout(this.initDelayId);
      }
      if (!this.sessionId) {
        this.log.debug('can\'t close widget without sessionId');
        return;
      }
      this.log.debug('close widget');
      if (event) {
        event.stopPropagation();
      }
      this.sessionClose();
      if (this.isFullscreen) {
        this.enableScrollOnRoot();
      }
      remainerHeight = this.el.height() - this.el.find('.zammad-chat-header').outerHeight();
      return this.el.animate({
        bottom: -remainerHeight
      }, 500, this.onCloseAnimationEnd);
    };

    ZammadChat.prototype.onCloseAnimationEnd = function() {
      var base;
      this.el.css('bottom', '');
      this.el.removeClass('zammad-chat-is-open');
      this.showLoader();
      this.el.find('.zammad-chat-welcome').removeClass('zammad-chat-is-hidden');
      this.el.find('.zammad-chat-agent').addClass('zammad-chat-is-hidden');
      this.el.find('.zammad-chat-agent-status').addClass('zammad-chat-is-hidden');
      this.isOpen = false;
      if (typeof (base = this.options).onCloseAnimationEnd === "function") {
        base.onCloseAnimationEnd();
      }
      return this.io.reconnect();
    };

    ZammadChat.prototype.onWebSocketClose = function() {
      if (this.isOpen) {
        return;
      }
      if (this.el) {
        this.el.removeClass('zammad-chat-is-shown');
        return this.el.removeClass('zammad-chat-is-loaded');
      }
    };

    ZammadChat.prototype.show = function() {
      if (this.state === 'offline') {
        return;
      }
      this.el.addClass('zammad-chat-is-loaded');
      return this.el.addClass('zammad-chat-is-shown');
    };

    ZammadChat.prototype.disableInput = function() {
      this.input.prop('disabled', true);
      return this.el.find('.zammad-chat-send').prop('disabled', true);
    };

    ZammadChat.prototype.enableInput = function() {
      this.input.prop('disabled', false);
      return this.el.find('.zammad-chat-send').prop('disabled', false);
    };

    ZammadChat.prototype.hideModal = function() {
      return this.el.find('.zammad-chat-modal').html('');
    };

    ZammadChat.prototype.onQueueScreen = function(data) {
      var show;
      this.setSessionId(data.session_id);
      show = (function(_this) {
        return function() {
          _this.onQueue(data);
          return _this.waitingListTimeout.start();
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

    ZammadChat.prototype.onQueue = function(data) {
      this.log.notice('onQueue', data.position);
      this.inQueue = true;
      return this.el.find('.zammad-chat-modal').html(this.view('waiting')({
        position: data.position
      }));
    };

    ZammadChat.prototype.onAgentTypingStart = function() {
      if (this.stopTypingId) {
        clearTimeout(this.stopTypingId);
      }
      this.stopTypingId = setTimeout(this.onAgentTypingEnd, 3000);
      if (this.el.find('.zammad-chat-message--typing').get(0)) {
        return;
      }
      this.maybeAddTimestamp();
      this.el.find('.zammad-chat-body').append(this.view('typingIndicator')());
      if (!this.isVisible(this.el.find('.zammad-chat-message--typing'), true)) {
        return;
      }
      return this.scrollToBottom();
    };

    ZammadChat.prototype.onAgentTypingEnd = function() {
      return this.el.find('.zammad-chat-message--typing').remove();
    };

    ZammadChat.prototype.onLeaveTemporary = function() {
      if (!this.sessionId) {
        return;
      }
      return this.send('chat_session_leave_temporary', {
        session_id: this.sessionId
      });
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
          this.el.find('.zammad-chat-body').append(this.view('timestamp')({
            label: label,
            time: time
          }));
          this.lastTimestamp = timestamp;
          this.lastAddedType = 'timestamp';
          return this.scrollToBottom();
        }
      }
    };

    ZammadChat.prototype.updateLastTimestamp = function(label, time) {
      if (!this.el) {
        return;
      }
      return this.el.find('.zammad-chat-body').find('.zammad-chat-timestamp').last().replaceWith(this.view('timestamp')({
        label: label,
        time: time
      }));
    };

    ZammadChat.prototype.addStatus = function(status) {
      if (!this.el) {
        return;
      }
      this.maybeAddTimestamp();
      this.el.find('.zammad-chat-body').append(this.view('status')({
        status: status
      }));
      return this.scrollToBottom();
    };

    ZammadChat.prototype.detectScrolledtoBottom = function() {
      var scrollBottom;
      scrollBottom = this.el.find('.zammad-chat-body').scrollTop() + this.el.find('.zammad-chat-body').outerHeight();
      this.scrolledToBottom = Math.abs(scrollBottom - this.el.find('.zammad-chat-body').prop('scrollHeight')) <= this.scrollSnapTolerance;
      if (this.scrolledToBottom) {
        return this.el.find('.zammad-scroll-hint').addClass('is-hidden');
      }
    };

    ZammadChat.prototype.showScrollHint = function() {
      this.el.find('.zammad-scroll-hint').removeClass('is-hidden');
      return this.el.find('.zammad-chat-body').scrollTop(this.el.find('.zammad-chat-body').scrollTop() + this.el.find('.zammad-scroll-hint').outerHeight());
    };

    ZammadChat.prototype.onScrollHintClick = function() {
      return this.el.find('.zammad-chat-body').animate({
        scrollTop: this.el.find('.zammad-chat-body').prop('scrollHeight')
      }, 300);
    };

    ZammadChat.prototype.scrollToBottom = function(arg) {
      var showHint;
      showHint = (arg != null ? arg : {
        showHint: false
      }).showHint;
      if (this.scrolledToBottom) {
        return this.el.find('.zammad-chat-body').scrollTop($('.zammad-chat-body').prop('scrollHeight'));
      } else if (showHint) {
        return this.showScrollHint();
      }
    };

    ZammadChat.prototype.destroy = function(params) {
      if (params == null) {
        params = {};
      }
      this.log.debug('destroy widget', params);
      this.setAgentOnlineState('offline');
      if (params.remove && this.el) {
        this.el.remove();
      }
      if (this.waitingListTimeout) {
        this.waitingListTimeout.stop();
      }
      if (this.inactiveTimeout) {
        this.inactiveTimeout.stop();
      }
      if (this.idleTimeout) {
        this.idleTimeout.stop();
      }
      return this.io.close();
    };

    ZammadChat.prototype.reconnect = function() {
      this.log.notice('reconnecting');
      this.disableInput();
      this.lastAddedType = 'status';
      this.setAgentOnlineState('connecting');
      return this.addStatus(this.T('Connection lost'));
    };

    ZammadChat.prototype.onConnectionReestablished = function() {
      var base;
      this.lastAddedType = 'status';
      this.setAgentOnlineState('online');
      this.addStatus(this.T('Connection re-established'));
      return typeof (base = this.options).onConnectionReestablished === "function" ? base.onConnectionReestablished() : void 0;
    };

    ZammadChat.prototype.onSessionClosed = function(data) {
      var base;
      this.addStatus(this.T('Chat closed by %s', data.realname));
      this.disableInput();
      this.setAgentOnlineState('offline');
      this.inactiveTimeout.stop();
      return typeof (base = this.options).onSessionClosed === "function" ? base.onSessionClosed(data) : void 0;
    };

    ZammadChat.prototype.setSessionId = function(id) {
      this.sessionId = id;
      if (id === void 0) {
        return sessionStorage.removeItem('sessionId');
      } else {
        return sessionStorage.setItem('sessionId', id);
      }
    };

    ZammadChat.prototype.onConnectionEstablished = function(data) {
      var base;
      if (this.onInitialQueueDelayId) {
        clearTimeout(this.onInitialQueueDelayId);
      }
      this.inQueue = false;
      if (data.agent) {
        this.agent = data.agent;
      }
      if (data.session_id) {
        this.setSessionId(data.session_id);
      }
      this.el.find('.zammad-chat-body').html('');
      this.el.find('.zammad-chat-agent').html(this.view('agent')({
        agent: this.agent
      }));
      this.enableInput();
      this.hideModal();
      this.el.find('.zammad-chat-welcome').addClass('zammad-chat-is-hidden');
      this.el.find('.zammad-chat-agent').removeClass('zammad-chat-is-hidden');
      this.el.find('.zammad-chat-agent-status').removeClass('zammad-chat-is-hidden');
      if (!this.isFullscreen) {
        this.input.focus();
      }
      this.setAgentOnlineState('online');
      this.waitingListTimeout.stop();
      this.idleTimeout.stop();
      this.inactiveTimeout.start();
      return typeof (base = this.options).onConnectionEstablished === "function" ? base.onConnectionEstablished(data) : void 0;
    };

    ZammadChat.prototype.showCustomerTimeout = function() {
      var reload;
      this.el.find('.zammad-chat-modal').html(this.view('customer_timeout')({
        agent: this.agent.name,
        delay: this.options.inactiveTimeout
      }));
      reload = function() {
        return location.reload();
      };
      this.el.find('.js-restart').click(reload);
      return this.sessionClose();
    };

    ZammadChat.prototype.showWaitingListTimeout = function() {
      var reload;
      this.el.find('.zammad-chat-modal').html(this.view('waiting_list_timeout')({
        delay: this.options.watingListTimeout
      }));
      reload = function() {
        return location.reload();
      };
      this.el.find('.js-restart').click(reload);
      return this.sessionClose();
    };

    ZammadChat.prototype.showLoader = function() {
      return this.el.find('.zammad-chat-modal').html(this.view('loader')());
    };

    ZammadChat.prototype.setAgentOnlineState = function(state) {
      var capitalizedState;
      this.state = state;
      if (!this.el) {
        return;
      }
      capitalizedState = state.charAt(0).toUpperCase() + state.slice(1);
      return this.el.find('.zammad-chat-agent-status').attr('data-status', state).text(this.T(capitalizedState));
    };

    ZammadChat.prototype.detectHost = function() {
      var protocol;
      protocol = 'ws://';
      if (scriptProtocol === 'https') {
        protocol = 'wss://';
      }
      return this.options.host = "" + protocol + scriptHost + "/ws";
    };

    ZammadChat.prototype.loadCss = function() {
      var newSS, styles, url;
      if (!this.options.cssAutoload) {
        return;
      }
      url = this.options.cssUrl;
      if (!url) {
        url = this.options.host.replace(/^wss/i, 'https').replace(/^ws/i, 'http').replace(/\/ws/i, '');
        url += '/assets/chat/chat.css';
      }
      this.log.debug("load css from '" + url + "'");
      styles = "@import url('" + url + "');";
      newSS = document.createElement('link');
      newSS.onload = this.onCssLoaded;
      newSS.rel = 'stylesheet';
      newSS.href = 'data:text/css,' + escape(styles);
      return document.getElementsByTagName('head')[0].appendChild(newSS);
    };

    ZammadChat.prototype.onCssLoaded = function() {
      var base;
      this.cssLoaded = true;
      if (this.socketReady) {
        this.onReady();
      }
      return typeof (base = this.options).onCssLoaded === "function" ? base.onCssLoaded() : void 0;
    };

    ZammadChat.prototype.startTimeoutObservers = function() {
      this.idleTimeout = new Timeout({
        logPrefix: 'idleTimeout',
        debug: this.options.debug,
        timeout: this.options.idleTimeout,
        timeoutIntervallCheck: this.options.idleTimeoutIntervallCheck,
        callback: (function(_this) {
          return function() {
            _this.log.debug('Idle timeout reached, hide widget', new Date);
            return _this.destroy({
              remove: true
            });
          };
        })(this)
      });
      this.inactiveTimeout = new Timeout({
        logPrefix: 'inactiveTimeout',
        debug: this.options.debug,
        timeout: this.options.inactiveTimeout,
        timeoutIntervallCheck: this.options.inactiveTimeoutIntervallCheck,
        callback: (function(_this) {
          return function() {
            _this.log.debug('Inactive timeout reached, show timeout screen.', new Date);
            _this.showCustomerTimeout();
            return _this.destroy({
              remove: false
            });
          };
        })(this)
      });
      return this.waitingListTimeout = new Timeout({
        logPrefix: 'waitingListTimeout',
        debug: this.options.debug,
        timeout: this.options.waitingListTimeout,
        timeoutIntervallCheck: this.options.waitingListTimeoutIntervallCheck,
        callback: (function(_this) {
          return function() {
            _this.log.debug('Waiting list timeout reached, show timeout screen.', new Date);
            _this.showWaitingListTimeout();
            return _this.destroy({
              remove: false
            });
          };
        })(this)
      });
    };

    ZammadChat.prototype.disableScrollOnRoot = function() {
      this.rootScrollOffset = this.scrollRoot.scrollTop();
      return this.scrollRoot.css({
        overflow: 'hidden',
        position: 'fixed'
      });
    };

    ZammadChat.prototype.enableScrollOnRoot = function() {
      this.scrollRoot.scrollTop(this.rootScrollOffset);
      return this.scrollRoot.css({
        overflow: '',
        position: ''
      });
    };

    ZammadChat.prototype.isVisible = function(el, partial, hidden, direction) {
      var $t, $w, _bottom, _left, _right, _top, bViz, clientSize, compareBottom, compareLeft, compareRight, compareTop, hVisible, lViz, offset, rViz, rec, t, tViz, vVisible, viewBottom, viewLeft, viewRight, viewTop, vpHeight, vpWidth;
      if (el.length < 1) {
        return;
      }
      $w = $(window);
      $t = el.length > 1 ? el.eq(0) : el;
      t = $t.get(0);
      vpWidth = $w.width();
      vpHeight = $w.height();
      direction = direction ? direction : 'both';
      clientSize = hidden === true ? t.offsetWidth * t.offsetHeight : true;
      if (typeof t.getBoundingClientRect === 'function') {
        rec = t.getBoundingClientRect();
        tViz = rec.top >= 0 && rec.top < vpHeight;
        bViz = rec.bottom > 0 && rec.bottom <= vpHeight;
        lViz = rec.left >= 0 && rec.left < vpWidth;
        rViz = rec.right > 0 && rec.right <= vpWidth;
        vVisible = partial ? tViz || bViz : tViz && bViz;
        hVisible = partial ? lViz || rViz : lViz && rViz;
        if (direction === 'both') {
          return clientSize && vVisible && hVisible;
        } else if (direction === 'vertical') {
          return clientSize && vVisible;
        } else if (direction === 'horizontal') {
          return clientSize && hVisible;
        }
      } else {
        viewTop = $w.scrollTop();
        viewBottom = viewTop + vpHeight;
        viewLeft = $w.scrollLeft();
        viewRight = viewLeft + vpWidth;
        offset = $t.offset();
        _top = offset.top;
        _bottom = _top + $t.height();
        _left = offset.left;
        _right = _left + $t.width();
        compareTop = partial === true ? _bottom : _top;
        compareBottom = partial === true ? _top : _bottom;
        compareLeft = partial === true ? _right : _left;
        compareRight = partial === true ? _left : _right;
        if (direction === 'both') {
          return !!clientSize && ((compareBottom <= viewBottom) && (compareTop >= viewTop)) && ((compareRight <= viewRight) && (compareLeft >= viewLeft));
        } else if (direction === 'vertical') {
          return !!clientSize && ((compareBottom <= viewBottom) && (compareTop >= viewTop));
        } else if (direction === 'horizontal') {
          return !!clientSize && ((compareRight <= viewRight) && (compareLeft >= viewLeft));
        }
      }
    };

    ZammadChat.prototype.isRetina = function() {
      var mq;
      if (window.matchMedia) {
        mq = window.matchMedia('only screen and (min--moz-device-pixel-ratio: 1.3), only screen and (-o-min-device-pixel-ratio: 2.6/2), only screen and (-webkit-min-device-pixel-ratio: 1.3), only screen  and (min-device-pixel-ratio: 1.3), only screen and (min-resolution: 1.3dppx)');
        return mq && mq.matches || (window.devicePixelRatio > 1);
      }
      return false;
    };

    ZammadChat.prototype.resizeImage = function(dataURL, x, y, sizeFactor, type, quallity, callback, force) {
      var imageObject;
      if (x == null) {
        x = 'auto';
      }
      if (y == null) {
        y = 'auto';
      }
      if (sizeFactor == null) {
        sizeFactor = 1;
      }
      if (force == null) {
        force = true;
      }
      imageObject = new Image();
      imageObject.onload = function() {
        var canvas, context, factor, imageHeight, imageWidth, newDataUrl, resize;
        imageWidth = imageObject.width;
        imageHeight = imageObject.height;
        console.log('ImageService', 'current size', imageWidth, imageHeight);
        if (y === 'auto' && x === 'auto') {
          x = imageWidth;
          y = imageHeight;
        }
        if (y === 'auto') {
          factor = imageWidth / x;
          y = imageHeight / factor;
        }
        if (x === 'auto') {
          factor = imageWidth / y;
          x = imageHeight / factor;
        }
        resize = false;
        if (x < imageWidth || y < imageHeight) {
          resize = true;
          x = x * sizeFactor;
          y = y * sizeFactor;
        } else {
          x = imageWidth;
          y = imageHeight;
        }
        canvas = document.createElement('canvas');
        canvas.width = x;
        canvas.height = y;
        context = canvas.getContext('2d');
        context.drawImage(imageObject, 0, 0, x, y);
        if (quallity === 'auto') {
          if (x < 200 && y < 200) {
            quallity = 1;
          } else if (x < 400 && y < 400) {
            quallity = 0.9;
          } else if (x < 600 && y < 600) {
            quallity = 0.8;
          } else if (x < 900 && y < 900) {
            quallity = 0.7;
          } else {
            quallity = 0.6;
          }
        }
        newDataUrl = canvas.toDataURL(type, quallity);
        if (resize) {
          console.log('ImageService', 'resize', x / sizeFactor, y / sizeFactor, quallity, (newDataUrl.length * 0.75) / 1024 / 1024, 'in mb');
          callback(newDataUrl, x / sizeFactor, y / sizeFactor, true);
          return;
        }
        console.log('ImageService', 'no resize', x, y, quallity, (newDataUrl.length * 0.75) / 1024 / 1024, 'in mb');
        return callback(newDataUrl, x, y, false);
      };
      return imageObject.src = dataURL;
    };

    ZammadChat.prototype.pasteHtmlAtCaret = function(html) {
      var el, frag, lastNode, node, range, sel;
      sel = void 0;
      range = void 0;
      if (window.getSelection) {
        sel = window.getSelection();
        if (sel.getRangeAt && sel.rangeCount) {
          range = sel.getRangeAt(0);
          range.deleteContents();
          el = document.createElement('div');
          el.innerHTML = html;
          frag = document.createDocumentFragment(node, lastNode);
          while (node = el.firstChild) {
            lastNode = frag.appendChild(node);
          }
          range.insertNode(frag);
          if (lastNode) {
            range = range.cloneRange();
            range.setStartAfter(lastNode);
            range.collapse(true);
            sel.removeAllRanges();
            return sel.addRange(range);
          }
        }
      } else if (document.selection && document.selection.type !== 'Control') {
        return document.selection.createRange().pasteHTML(html);
      }
    };

    ZammadChat.prototype.wordFilter = function(editor) {
      var content, last_level, pnt;
      content = editor.html();
      content = content.replace(/<!--[\s\S]+?-->/gi, '');
      content = content.replace(/<(!|script[^>]*>.*?<\/script(?=[>\s])|\/?(\?xml(:\w+)?|img|meta|link|style|\w:\w+)(?=[\s\/>]))[^>]*>/gi, '');
      content = content.replace(/<(\/?)s>/gi, '<$1strike>');
      content = content.replace(/&nbsp;/gi, ' ');
      editor.html(content);
      $('p', editor).each(function() {
        var matches, str;
        str = $(this).attr('style');
        matches = /mso-list:\w+ \w+([0-9]+)/.exec(str);
        if (matches) {
          return $(this).data('_listLevel', parseInt(matches[1], 10));
        }
      });
      last_level = 0;
      pnt = null;
      $('p', editor).each(function() {
        var cur_level, i, j, list_tag, matches, ref, ref1, ref2, start, txt;
        cur_level = $(this).data('_listLevel');
        if (cur_level !== void 0) {
          txt = $(this).text();
          list_tag = '<ul></ul>';
          if (/^\s*\w+\./.test(txt)) {
            matches = /([0-9])\./.exec(txt);
            if (matches) {
              start = parseInt(matches[1], 10);
              list_tag = (ref = start > 1) != null ? ref : '<ol start="' + start + {
                '"></ol>': '<ol></ol>'
              };
            } else {
              list_tag = '<ol></ol>';
            }
          }
          if (cur_level > last_level) {
            if (last_level === 0) {
              $(this).before(list_tag);
              pnt = $(this).prev();
            } else {
              pnt = $(list_tag).appendTo(pnt);
            }
          }
          if (cur_level < last_level) {
            for (i = j = ref1 = i, ref2 = last_level - cur_level; ref1 <= ref2 ? j <= ref2 : j >= ref2; i = ref1 <= ref2 ? ++j : --j) {
              pnt = pnt.parent();
            }
          }
          $('span:first', this).remove();
          pnt.append('<li>' + $(this).html() + '</li>');
          $(this).remove();
          return last_level = cur_level;
        } else {
          return last_level = 0;
        }
      });
      $('[style]', editor).removeAttr('style');
      $('[align]', editor).removeAttr('align');
      $('span', editor).replaceWith(function() {
        return $(this).contents();
      });
      $('span:empty', editor).remove();
      $("[class^='Mso']", editor).removeAttr('class');
      $('p:empty', editor).remove();
      return editor;
    };

    ZammadChat.prototype.removeAttribute = function(element) {
      var $element, att, j, len, ref;
      if (!element) {
        return;
      }
      $element = $(element);
      ref = element.attributes;
      for (j = 0, len = ref.length; j < len; j++) {
        att = ref[j];
        if (att && att.name) {
          element.removeAttribute(att.name);
        }
      }
      return $element.removeAttr('style').removeAttr('class').removeAttr('lang').removeAttr('type').removeAttr('align').removeAttr('id').removeAttr('wrap').removeAttr('title');
    };

    ZammadChat.prototype.removeAttributes = function(html, parent) {
      if (parent == null) {
        parent = true;
      }
      if (parent) {
        html.each((function(_this) {
          return function(index, element) {
            return _this.removeAttribute(element);
          };
        })(this));
      }
      html.find('*').each((function(_this) {
        return function(index, element) {
          return _this.removeAttribute(element);
        };
      })(this));
      return html;
    };

    return ZammadChat;

  })(Base);
  return window.ZammadChat = ZammadChat;
})(window.jQuery, window);

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["loader"] = function(__obj) {
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
      __out.push('<span class="zammad-chat-loading-animation">\n  <span class="zammad-chat-loading-circle"></span>\n  <span class="zammad-chat-loading-circle"></span>\n  <span class="zammad-chat-loading-circle"></span>\n</span>\n<span class="zammad-chat-modal-text">');
    
      __out.push(this.T('Connecting'));
    
      __out.push('</span>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["message"] = function(__obj) {
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
    
      __out.push(__sanitize(this.unreadClass));
    
      __out.push('">\n  <span class="zammad-chat-message-body"');
    
      if (this.background && this.from === 'customer') {
        __out.push(__sanitize(" style='background: " + this.background + "'"));
      }
    
      __out.push('>');
    
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
window.zammadChatTemplates["status"] = function(__obj) {
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
      __out.push('<div class="zammad-chat-status">\n  <div class="zammad-chat-status-inner">\n    ');
    
      __out.push(this.status);
    
      __out.push('\n  </div>\n</div>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["timestamp"] = function(__obj) {
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
      __out.push('<div class="zammad-chat-timestamp"><strong>');
    
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
window.zammadChatTemplates["typingIndicator"] = function(__obj) {
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
window.zammadChatTemplates["waiting"] = function(__obj) {
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
      __out.push('<div class="zammad-chat-modal-text">\n  <span class="zammad-chat-loading-animation">\n    <span class="zammad-chat-loading-circle"></span>\n    <span class="zammad-chat-loading-circle"></span>\n    <span class="zammad-chat-loading-circle"></span>\n  </span>\n  ');
    
      __out.push(this.T('All colleagues are busy.'));
    
      __out.push('<br>\n  ');
    
      __out.push(this.T('You are on waiting list position <strong>%s</strong>.', this.position));
    
      __out.push('\n</div>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["waiting_list_timeout"] = function(__obj) {
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
      __out.push('<div class="zammad-chat-modal-text">\n  ');
    
      __out.push(this.T('We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!'));
    
      __out.push('\n  <br>\n  <div class="zammad-chat-button js-restart"');
    
      if (this.background) {
        __out.push(__sanitize(" style='background: " + this.background + "'"));
      }
    
      __out.push('>');
    
      __out.push(this.T('Start new conversation'));
    
      __out.push('</div>\n</div>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
