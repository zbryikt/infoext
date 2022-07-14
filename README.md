# chromext

A sample / boilerplate for making Chrome extension.

You will still need some basic knowledge about how to make a chrome extension: 

 - https://developer.chrome.com/docs/extensions/mv3/getstarted/


## Quick Start

A minimal Chrome extension is composed of following files:

 - `manifest.json`: like `package.json` for information about this extension.
 - `background.js`: script to run in background for this extension.
 - `popup.html`: html for rendering the extension's popup.

Basically these files are in the same directory while you can specify their location within `manifest.json`. Here we use `@zbryikt/template` to build source pug / livescript files into a web static directory for used as a chrome extension.


