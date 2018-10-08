module.exports = `<div class="zammad-chat zammad-chat-is-open" style="font-size: 12px; bottom: 0px;">
  <div class="zammad-chat-header js-chat-open" style="background: rgb(255,121,15)">
    <div class="zammad-chat-header-controls js-chat-toggle">
      <span class="zammad-chat-agent-status zammad-chat-is-hidden js-chat-status" data-status="offline">Offline</span>
      <span class="zammad-chat-header-icon">
        <svg class="zammad-chat-header-icon-open" width="13" height="7" viewBox="0 0 13 7"><path d="M10.807 7l1.4-1.428-5-4.9L6.5-.02l-.7.7-4.9 4.9 1.414 1.413L6.5 2.886 10.807 7z" fill-rule="evenodd"></path></svg>
        <svg class="zammad-chat-header-icon-close" width="13" height="13" viewBox="0 0 13 13"><path d="m2.241.12l-2.121 2.121 4.243 4.243-4.243 4.243 2.121 2.121 4.243-4.243 4.243 4.243 2.121-2.121-4.243-4.243 4.243-4.243-2.121-2.121-4.243 4.243-4.243-4.243" fill-rule="evenodd"></path></svg>
      </span>
    </div>
    <div class="zammad-chat-agent zammad-chat-is-hidden">
    </div>
    <div class="zammad-chat-welcome">
      <svg class="zammad-chat-icon" viewBox="0 0 24 24" width="24" height="24"><path d="M2 5C2 4 3 3 4 3h16c1 0 2 1 2 2v10C22 16 21 17 20 17H4C3 17 2 16 2 15V5zM12 17l6 4v-4h-6z"></path></svg>
      <span class="zammad-chat-welcome-text"><strong>Chat</strong> with us!</span>
    </div>
  </div>
  <div class="zammad-chat-modal"><div class="zammad-chat-modal-text">
  <span class="zammad-chat-loading-animation">
    <span class="zammad-chat-loading-circle"></span>
    <span class="zammad-chat-loading-circle"></span>
    <span class="zammad-chat-loading-circle"></span>
  </span>
  All colleagues are busy.<br>
  You are on waiting list position <strong>1</strong>.
</div></div>
  <div class="zammad-scroll-hint is-hidden">
    <svg class="zammad-scroll-hint-icon" width="20" height="18" viewBox="0 0 20 18"><path d="M0,2.00585866 C0,0.898053512 0.898212381,0 1.99079514,0 L18.0092049,0 C19.1086907,0 20,0.897060126 20,2.00585866 L20,11.9941413 C20,13.1019465 19.1017876,14 18.0092049,14 L1.99079514,14 C0.891309342,14 0,13.1029399 0,11.9941413 L0,2.00585866 Z M10,14 L16,18 L16,14 L10,14 Z" fill-rule="evenodd"></path></svg>
    Scroll down to see new messages
  </div>
  <div class="zammad-chat-body"><div class="zammad-chat-timestamp"><strong>Today</strong> 01:09</div><div class="zammad-chat-status">
  <div class="zammad-chat-status-inner">
    Connection lost...
  </div>
</div></div>
  <form class="zammad-chat-controls">
    <div class="zammad-chat-input" rows="1" placeholder="Compose your message..." contenteditable="true"></div>
    <button type="submit" class="zammad-chat-button zammad-chat-send" style="background: rgb(255,121,15)" disabled="">Send</button>
  </form>
</div>`
