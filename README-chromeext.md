# chromext

A sample / boilerplate for making Chrome extension.

You will still need some basic knowledge about how to make a chrome extension: 

 - https://developer.chrome.com/docs/extensions/mv3/getstarted/


## Quick Start

A minimal Chrome extension is composed of following files:

 - `manifest.json`: like `package.json` for information about this extension.
 - background script: script to run in background for this extension.
 - content scripts: script to run in web pages. Can retrieve page content and modify DOM.
 - popup html: html for rendering the extension's popup.

Basically these files are in the same directory while you can specify their location within `manifest.json`. Here we use `@zbryikt/template` to build source pug / livescript files into a web static directory for used as a chrome extension.


### Extension Load / Reload

use `chrome://extensions` -> `load unpacked` -> your static directory to load a dev extension.

To reload an extension, call `chrome.runtime.reload()` anywhere (e.g., in popup script or background script). You can even inspect popup widget to open dev console, and run `chrome.runtime.reload()` there.



## Content Script 

Content script can be injected declaratively or programmatically. Following is an example of declarative injection with `manifest.json`:

    "content_scripts": [
      {
        "matches": ["http://*.nytimes.com/*"], // <all_urls>
        "exclude_matches": ["*://*/*business*"],
        "include_globs": ["*nytimes.com/???s/*"],
        "exclude_globs": ["*science*"],
        "run_at": "document_idle", // 決定 JavaScript 注入的時間，預設是 document_idle
        "css": ["myStyles.css"],
        "js": ["contentScript.js"]
      }
    ]



Alternatively, inject programmatically:

    chrome.runtime.onMessage.addListener (msg, cb) ->
      # by string
      chrome.tabs.executeScript code: '....'
      # or, some file
      chrome.tabs.executeScript file: 'somefile.js'


To communicate with host script, use `message` event:

    # content script
    window.addEventListener \message, (evt) -> ...
      
    # script in webpage
    window.postMessage type: '...', text: '..."
