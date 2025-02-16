var lderror, dollm, ref$;
lderror = {
  reject: function(){
    return Promise.reject(e);
  }
};
dollm = {};
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
dollm.thread = function(opt){
  opt == null && (opt = {});
  this._ = {
    name: opt.name || 'general chatbot',
    stateless: opt.stateless || false,
    id: opt.id || (typeof suuid != 'undefined' && suuid !== null
      ? suuid()
      : Math.random().toString(36).substring(2)),
    proc: opt.proc || function(){},
    opt: opt.opt || {},
    url: opt.url || '',
    model: opt.model || ''
  };
  this.messages = [{
    role: 'system',
    content: opt.system || 'you are a general chatbot.'
  }];
  return this;
};
dollm.thread.prototype = (ref$ = Object.create(Object.prototype), ref$.name = function(){
  return this._.name || 'general chatbot';
}, ref$.model = function(){
  return this._.model || 'default model';
}, ref$.send = function(arg$){
  var message, proc, ref$, ref1$, ref2$, this$ = this;
  message = arg$.message, proc = arg$.proc;
  this.messages.push({
    role: 'user',
    content: message
  });
  return this._send((ref1$ = (ref2$ = {
    messages: this.messages
  }, ref2$.model = (ref$ = this._).model, ref2$.opt = ref$.opt, ref2$.url = ref$.url, ref2$), ref1$.proc = proc || this._.proc || function(){}, ref1$)).then(function(it){
    if (this$._.stateless) {
      this$.messages.pop();
    } else {
      this$.messages.push({
        role: 'assistant',
        content: it.buf
      });
    }
    return it;
  });
}, ref$._send = function(arg$){
  var messages, proc, model, opt, url, cfg;
  messages = arg$.messages, proc = arg$.proc, model = arg$.model, opt = arg$.opt, url = arg$.url;
  if (!opt) {
    opt = {};
  }
  if (!url) {
    url = 'http://localhost:11434/api/chat';
  }
  if (!this._.controller) {
    this._.controller = new AbortController();
  }
  cfg = {
    method: 'POST',
    headers: import$({
      "Content-Type": 'application/json'
    }, (opt || {}).headers || {}),
    body: JSON.stringify({
      model: model || 'gemma2:9b',
      messages: messages || []
    }),
    signal: this._.controller.signal
  };
  return fetch(url, cfg).then(function(res){
    var reader, decoder, lc, _proc, _;
    reader = res.body.getReader();
    decoder = new TextDecoder();
    lc = {
      buf: ''
    };
    _proc = function(o){
      var txt;
      o == null && (o = {});
      txt = o.message && o.message.role === 'assistant'
        ? o.message.content || ''
        : o.response || '';
      return proc(txt);
    };
    _ = function(){
      return reader.read().then(function(arg$){
        var done, value, e, lines;
        done = arg$.done, value = arg$.value;
        if (done) {
          if (lc.buf.trim()) {
            try {
              _proc(JSON.parse(buf));
            } catch (e$) {
              e = e$;
              lderror.reject(e);
            }
          }
          return Promise.resolve(lc);
        }
        lc.buf += decoder.decode(value, {
          stream: true
        });
        lines = lc.buf.split('\n');
        lc.buf = lines.pop();
        lines.forEach(function(l){
          var e;
          if (l.trim()) {
            try {
              return _proc(JSON.parse(l));
            } catch (e$) {
              e = e$;
              return lderror.reject(e);
            }
          }
        });
        return _();
      });
    };
    return _();
  });
}, ref$.abort = function(){
  if (!this._.controller) {
    return;
  }
  this._.controller.abort();
  return this._.controller = null;
}, ref$);
function import$(obj, src){
  var own = {}.hasOwnProperty;
  for (var key in src) if (own.call(src, key)) obj[key] = src[key];
  return obj;
}