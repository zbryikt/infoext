var bubble, ref$, bubbles, inputs, getContext;
console.log('[infoext] content script run');
bubble = function(o){
  var sel, range, rect, ref$, x, y, this$ = this;
  o == null && (o = {});
  this.session = o.session;
  sel = window.getSelection();
  if (sel.rangeCount > 0) {
    range = sel.getRangeAt(0);
    rect = range.getBoundingClientRect();
    ref$ = [rect.left + window.scrollX, rect.top + window.scrollY], x = ref$[0], y = ref$[1];
  } else {
    ref$ = [32 + window.scrollX, 32 + window.scrollY], x = ref$[0], y = ref$[1];
  }
  if (x + 432 > window.innerWidth) {
    x = window.innerWidth - 432;
  }
  this.node = document.createElement('div');
  ref$ = this.node.style;
  ref$.position = 'absolute';
  ref$.padding = '1em';
  ref$.whiteSpace = 'pre-wrap';
  ref$.borderRadius = '.5em';
  ref$.border = '1px solid #d6d7d8';
  ref$.boxShadow = '0 2px 4px rgba(0,0,0,.3)';
  ref$.background = '#fff';
  ref$.top = y + "px";
  ref$.left = x + "px";
  ref$.width = "400px";
  ref$.opacity = '.85';
  this.node.textContent = "loading...";
  this.node.addEventListener('click', function(){
    this$.node.style.display = 'none';
    return bubbles[this$.session] = null;
  });
  this.txt = "";
  document.body.appendChild(this.node);
  return this;
};
bubble.prototype = (ref$ = Object.create(Object.prototype), ref$.write = function(txt){
  return this.node.textContent = this.txt += txt;
}, ref$);
bubbles = {};
inputs = {};
chrome.runtime.onMessage.addListener(function(req, sender, res){
  var b, node, ret, n;
  if (req.action === 'summarize-start') {
    return bubbles[req.session] = {
      bubble: new bubble({
        session: req.session
      })
    };
  } else if (req.action === 'summarize-char') {
    if (!(b = (bubbles[req.session] || {}).bubble)) {
      return res({
        abort: true
      });
    }
    b.write(req.char);
    return res();
  } else if (req.action === 'input-context') {
    node = document.activeElement;
    if (!/textarea|input/gi.exec(node.tagName)) {
      return;
    }
    inputs[req.session] = {
      node: node,
      session: req.session
    };
    node._session = req.session;
    node.value = "";
    ret = getContext(node);
    return res(ret);
  } else if (req.action = 'generate-char') {
    if (!(n = (inputs[req.session] || {}).node)) {
      return res({
        abort: true
      });
    }
    n.value += req.char;
    return res();
  }
});
document.addEventListener('click', function(evt){
  var node;
  if (!((node = evt.target) && node._session)) {
    return;
  }
  return inputs[node._session] = null;
});
getContext = function(el){
  var range, rangeBefore, rangeAfter, textBefore, textAfter;
  range = document.createRange();
  rangeBefore = range.cloneRange();
  rangeAfter = range.cloneRange();
  rangeBefore.setStart(document.body, 0);
  rangeBefore.setEnd(el, 0);
  rangeAfter.setStart(el, 0);
  rangeAfter.setEndAfter(document.body.lastChild);
  textBefore = rangeBefore.toString().slice(-20);
  textAfter = rangeAfter.toString().slice(0, 20);
  return {
    before: textBefore,
    after: textAfter,
    type: el.tagName.toLowerCase()
  };
};