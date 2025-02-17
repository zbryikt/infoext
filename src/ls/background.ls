console.log "[infoext] background script run"

importScripts("dollm.js")

thread =
  summarizer: new dollm.thread do
    name: "Phi-4 測試機"
    model: "phi4:14b"
    stateless: true
    system: """
    你是一個文本摘要工具。用戶傳給你的文本，你會透過正體中文回覆其摘要過後的內容。
    """
  generator: new dollm.thread do
    name: "內容生成器"
    model: "phi4:14b"
    stateless: true
    system: """
    你是一個文本生成工具，幫用戶生成輸入框中的文字。為了提示你情境，用戶會傳給你兩段文字，第一段是輸入框之前的文字、第二段則是輸入框之後的文字，你可依這兩組文字隨機生成適合置於此輸入框中的文字。

    用戶亦會告訴你需要填入的元素是 input, textarea 或其它可能的元素名; input 需要較短的回應內容 (20 字內), textarea 則可以長一些 (50 ~ 300 字不等), 其它情況你可以自行衡量。

    請注意，用戶提供的前後文可能包含無關的訊息，因為那是用程式自動節錄的。你應該要自行判斷跟前後文最可能相關的輸入框內容，以前文來說就是最後面的文字、以後文來說就是最前面的文字，但前文的結尾會比後文的開頭還要重要。

    你生成回應時，請直接生成建議的內容，不要有歡迎詞、不要有思考過程，不要有任何嘗試與用戶討論的步驟。

    你會透過正體中文回覆。
    """

# sample handling request from content
# chrome.runtime.onMessage.addListener (msg, sender, reply) -> reply {text: "hello world"}

# install summarizer
chrome.runtime.onInstalled.addListener ->
  chrome.contextMenus.create do
    id: \summarize-selection
    title: "Summarize ..."
    contexts: ['selection']
  chrome.contextMenus.create do
    id: \generate-placeholder-text
    title: "Generate ..."
    contexts: ['editable']

# handle summarize request
chrome.contextMenus.onClicked.addListener (info, tab) !->
  if info.menuItemId == \summarize-selection
    txt = info.selection-text
    if !txt => return
    session = Math.random!toString(36)substring(2)
    console.log "[session #session] start to summarize text ( #{txt.length} bytes )"
    chrome.tabs.sendMessage tab.id, {action: "summarize-start", session: session}
    thread.summarizer.send do
      message: txt
      proc: (t) ~>
        try
          chrome.tabs.sendMessage(tab.id, {
            action: "summarize-char"
            session: session
            char: t
          }).then (r = {}) -> if r.abort => thread.summarizer.abort!
        catch e
          console.error e
          thread.summarizer.abort!
  else if info.menuItemId == \generate-placeholder-text
    session = Math.random!toString(36)substring(2)
    console.log "[session #session] generate placeholder text"
    chrome.tabs.sendMessage tab.id, {action: "input-context", session}
      .then (context) ->
        console.log context
        thread.generator.send do
          message: """
          元素類型：#{context.type}

          第一段文字：
          --------------------------
          #{context.before}
          --------------------------
          第二段文字：
          --------------------------
          #{context.after}
          """
          proc: (t) ~>
            try
              chrome.tabs.sendMessage(tab.id, {
                action: "generate-char"
                session: session
                char: t
              }).then (r = {}) -> if r.abort => thread.generator.abort!
            catch e
              console.error e
              thread.generator.abort!
