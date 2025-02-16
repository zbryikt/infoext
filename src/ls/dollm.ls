lderror = reject: -> Promise.reject e

dollm = {}
/*
dollm =
  send: -> @_send it
  _send: ({messages, proc, model, opt, url}) ->
    if !opt => opt = {}
    if !url => url = \http://localhost:11434/api/chat
    console.log "model: ", model
    cfg =
      method: \POST
      headers: { "Content-Type": \application/json } <<< ((opt or {}).headers or {})
      body: JSON.stringify({model: (model or 'gemma2:9b'), messages: messages or []})
    (res) <- fetch url, cfg .then _
    reader = res.body.getReader!
    decoder = new TextDecoder!
    lc = buf: ''
    _proc = (o={}) ->
      txt = if o.message and o.message.role == \assistant => o.message.content or ''
      else o.response or ''
      proc txt
    _ = ->
      ({done, value}) <- reader.read!then _
      if done =>
        if lc.buf.trim! => try _proc(JSON.parse(buf)) catch e => lderror.reject(e)
        return Promise.resolve lc
      lc.buf += decoder.decode value, {stream: true}
      lines = lc.buf.split \\n
      lc.buf = lines.pop!
      lines.for-each (l) -> if l.trim! => try _proc(JSON.parse(l)) catch e => lderror.reject(e)
      return _!
    _!
*/
dollm.thread = (opt = {}) ->
  @_ = {} <<<
    name: opt.name or 'general chatbot'
    stateless: opt.stateless or false
    id: opt.id or if suuid? => suuid! else Math.random!toString(36)substring(2)
    proc: (opt.proc or ->)
    opt: (opt.opt or {})
    url: (opt.url or '')
    model: opt.model or ''
  @messages = [
  * role: \system, content: opt.system or 'you are a general chatbot.'
  ]
  @
dollm.thread.prototype = Object.create(Object.prototype) <<<
  name: -> @_.name or 'general chatbot'
  model: -> @_.model or 'default model'
  send: ({message, proc}) ->
    @messages.push {role: \user, content: message}
    @_send({messages: @messages} <<< @_{model, opt, url} <<< {proc: proc or @_.proc or (->)})
      .then ~>
        if @_.stateless => @messages.pop!
        else @messages.push {role: \assistant, content: it.buf}
        return it
  _send: ({messages, proc, model, opt, url}) ->
    if !opt => opt = {}
    if !url => url = \http://localhost:11434/api/chat
    if !@_.controller => @_.controller = new AbortController!
    cfg =
      method: \POST
      headers: { "Content-Type": \application/json } <<< ((opt or {}).headers or {})
      body: JSON.stringify({model: (model or 'gemma2:9b'), messages: messages or []})
      signal: @_.controller.signal
    (res) <- fetch url, cfg .then _
    reader = res.body.getReader!
    decoder = new TextDecoder!
    lc = buf: ''
    _proc = (o={}) ->
      txt = if o.message and o.message.role == \assistant => o.message.content or ''
      else o.response or ''
      proc txt
    _ = ->
      ({done, value}) <- reader.read!then _
      if done =>
        if lc.buf.trim! => try _proc(JSON.parse(buf)) catch e => lderror.reject(e)
        return Promise.resolve lc
      lc.buf += decoder.decode value, {stream: true}
      lines = lc.buf.split \\n
      lc.buf = lines.pop!
      lines.for-each (l) -> if l.trim! => try _proc(JSON.parse(l)) catch e => lderror.reject(e)
      return _!
    _!
  abort: ->
    if !@_.controller => return
    @_.controller.abort!
    @_.controller = null
