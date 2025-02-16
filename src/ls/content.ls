console.log '[infoext] content script run'

# sample for sending message
#chrome.runtime.sendMessage { action: \generateText }, (response) -> console.log response

# sample for receiving message
#chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
#  console.log request.action, request.text
#  sendResponse success: true
#  return true

bubble = (o={}) ->
  @session = o.session
  sel = window.getSelection!
  if sel.rangeCount > 0 =>
    range = sel.getRangeAt(0)
    rect = range.getBoundingClientRect!
    [x, y] = [rect.left + window.scrollX, rect.top + window.scrollY]
  else [x, y] = [32 + window.scrollX, 32 + window.scrollY]
  if x + 432 > window.innerWidth => x = window.innerWidth - 432
  @node = document.createElement \div
  @node.style <<<
    position: \absolute
    padding: \1em
    whiteSpace: \pre-wrap
    borderRadius: \.5em
    border: '1px solid #d6d7d8'
    boxShadow: '0 2px 4px rgba(0,0,0,.3)'
    background: \#fff
    top: "#{y}px"
    left: "#{x}px"
    width: "400px"
    opacity: \.85
  @node.textContent = "loading..."
  @node.addEventListener \click, ~>
    @node.style.display = \none
    bubbles[@session] = null
  @txt = ""
  document.body.appendChild @node
  @

bubble.prototype = Object.create(Object.prototype) <<<
  write: (txt) -> @node.textContent = (@txt += txt)

bubbles = {}
inputs = {}

chrome.runtime.onMessage.addListener (req, sender, res) ->
  if req.action == \summarize-start =>
    bubbles[req.session] = {bubble: new bubble {session: req.session}}
  else if req.action == \summarize-char =>
    if !(b = (bubbles[req.session] or {}).bubble) => return res abort: true
    b.write req.char
    res!
  else if req.action == \input-context =>
    node = document.activeElement
    if !/textarea|input/gi.exec(node.tagName) => return
    inputs[req.session] = {node, session: req.session}
    node._session = req.session
    node.value = ""
    ret = get-context node
    res ret
  else if req.action = \generate-char =>
    if !(n = (inputs[req.session] or {}).node) => return res abort: true
    n.value += req.char
    res!

document.addEventListener \click, (evt) ->
  if !((node = evt.target) and node._session) => return
  inputs[node._session] = null

get-context = (el) ->
  range = document.createRange!
  range-before = range.cloneRange!
  range-after = range.cloneRange!
  range-before.setStart document.body, 0
  range-before.setEnd el, 0
  range-after.setStart el, 0
  range-after.setEndAfter document.body.lastChild
  text-before = range-before.toString!slice -20
  text-after = range-after.toString!slice 0, 20
  return {before: text-before, after: text-after, type: el.tagName.toLowerCase!}
