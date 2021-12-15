import "phoenix_html"
import {Socket} from "phoenix"
// import {LiveSocket} from "./phoenix_live_view"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let nowSeconds = () => Math.round(Date.now() / 1000)

let execJS = (selector, attr) => {
  document.querySelectorAll(selector).forEach(el => liveSocket.execJS(el, el.getAttribute(attr)))
}

let Hooks = {}

Hooks.Flash = {
  mounted(){
    let hide = () => liveSocket.execJS(this.el, this.el.getAttribute("phx-click"))
    this.timer = setTimeout(() => hide(), 8000)
    this.el.addEventListener("phx:hide-start", () => clearTimeout(this.timer))
    this.el.addEventListener("mouseover", () => {
      clearTimeout(this.timer)
      this.timer = setTimeout(() => hide(), 8000)
    })
  },
  destroyed(){ clearTimeout(this.timer) }
}

Hooks.Menu = {
  getAttr(name){
    let val = this.el.getAttribute(name)
    if(val === null){ throw(new Error(`no ${name} attribute configured for menu`)) }
    return val
  },
  reset(){
    this.enabled = false
    this.activeClass = this.getAttr("data-active-class")
    this.deactivate(this.menuItems())
    this.activeItem = null
    window.removeEventListener("keydown", this.handleKeyDown)
  },
  destroyed(){ this.reset() },
  mounted(){
    this.menuItemsContainer = document.querySelector(`[aria-labelledby="${this.el.id}"]`)
    this.reset()
    this.handleKeyDown = (e) => this.onKeyDown(e)
    this.el.addEventListener("keydown", e => {
      if((e.key === "Enter" || e.key === " ") && e.currentTarget.isSameNode(this.el)){
        this.enabled = true
      }
    })
    this.el.addEventListener("click", e => {
      if(!e.currentTarget.isSameNode(this.el)){ return }

      window.addEventListener("keydown", this.handleKeyDown)
      // disable if button clicked and click was not a keyboard event
      if(this.enabled){
        window.requestAnimationFrame(() => this.activate(0))
      }
    })
    this.menuItemsContainer.addEventListener("phx:hide-start", () => this.reset())
  },
  activate(index, fallbackIndex){
    let menuItems = this.menuItems()
    this.activeItem = menuItems[index] || menuItems[fallbackIndex]
    this.activeItem.classList.add(this.activeClass)
    this.activeItem.focus()
  },
  deactivate(items){ items.forEach(item => item.classList.remove(this.activeClass)) },
  menuItems(){ return Array.from(this.menuItemsContainer.querySelectorAll("[role=menuitem]")) },
  onKeyDown(e){
    if(e.key === "Escape"){
      document.body.click()
      this.el.focus()
      this.reset()
    } else if(e.key === "Enter" && !this.activeItem){
      this.activate(0)
    } else if(e.key === "Enter"){
      this.activeItem.click()
    }
    if(e.key === "ArrowDown"){
      e.preventDefault()
      let menuItems = this.menuItems()
      this.deactivate(menuItems)
      this.activate(menuItems.indexOf(this.activeItem) + 1, 0)
    } else if(e.key === "ArrowUp"){
      e.preventDefault()
      let menuItems = this.menuItems()
      this.deactivate(menuItems)
      this.activate(menuItems.indexOf(this.activeItem) - 1, menuItems.length - 1)
    } else if (e.key === "Tab"){
      e.preventDefault()
    }
  }
}

Hooks.AudioPlayer = {
  mounted(){
    this.playbackBeganAt = null
    this.player = this.el.querySelector("audio")
    this.currentTime = this.el.querySelector("#player-time")
    this.duration = this.el.querySelector("#player-duration")
    this.progress = this.el.querySelector("#player-progress")
    let enableAudio = () => {
      if(this.player.src){
        document.removeEventListener("click", enableAudio)
        if(this.player.readyState === 0){
          this.player.play().catch(error => null)
          this.player.pause()
        }
      }
    }
    document.addEventListener("click", enableAudio)
    this.el.addEventListener("js:listen_now", () => this.play({sync: true}))
    this.el.addEventListener("js:play_pause", () => {
      if(this.player.paused){
        this.play()
      }
    })
    this.handleEvent("play", ({url, token, elapsed}) => {
      this.playbackBeganAt = nowSeconds() - elapsed
      let currentSrc = this.player.src.split("?")[0]
      if(currentSrc === url && this.player.paused){
        this.play({sync: true})
      } else if(currentSrc !== url) {
        this.player.src = `${url}?token=${token}`
        this.play({sync: true})
      }
    })
    this.handleEvent("pause", () => this.pause())
    this.handleEvent("stop", () => this.stop())
  },

  play(opts = {}){
    let {sync} = opts
    this.player.play().then(() => {
      if(sync){ this.player.currentTime = nowSeconds() - this.playbackBeganAt }
      this.progressTimer = setInterval(() => this.updateProgress(), 100)
    }, error => {
      if(error.name === "NotAllowedError"){
        execJS("#enable-audio", "data-js-show")
      }
    })
  },

  pause(){
    clearInterval(this.progressTimer)
    this.player.pause()
  },

  stop(){
    clearInterval(this.progressTimer)
    this.player.pause()
    this.player.currentTime = 0
    this.updateProgress()
    this.duration.innerText = ""
    this.currentTime.innerText = ""
  },

  updateProgress(){
    if(isNaN(this.player.duration)){ return false }
    if(this.player.currentTime >= this.player.duration){
      this.pushEvent("next_song_auto")
      clearInterval(this.progressTimer)
      return
    }
    this.progress.style.width = `${(this.player.currentTime / (this.player.duration) * 100)}%`
    this.duration.innerText = this.formatTime(this.player.duration)
    this.currentTime.innerText = this.formatTime(this.player.currentTime)
  },

  formatTime(seconds){ return new Date(1000 * seconds).toISOString().substr(14, 5) }
}

Hooks.Modal = {
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  isFocusable(element) {
    if (element == this.beforeFocusEl || element == this.afterFocusEl) {
      return false
    }
    if (element.tabIndex > 0 || (element.tabIndex === 0 && element.getAttribute("tabIndex") !== null)) {
      return true
    }
    if (element.disabled) {
      return false
    }
    switch (element.nodeName) {
      case "A":
        return !!element.href && element.rel != "ignore"
      case "INPUT":
        return element.type != "hidden" && element.type != "file"
      case "BUTTON":
      case "SELECT":
      case "TEXTAREA":
        return true
      default:
        return false
    }
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  attemptFocus(element) {
    if (!this.isFocusable(element)) {
      return false
    }
    try {
      element.focus()
    } catch (e) {
    }
    return document.activeElement === element
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  focusFirstDescendant(element) {
    for (var i = 0; i < element.childNodes.length; i++) {
      var child = element.childNodes[i]
      if (this.attemptFocus(child) || this.focusFirstDescendant(child)) {
        return true
      }
    }
    return false
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  focusLastDescendant(element) {
    for (var i = element.childNodes.length - 1; i >= 0; i--) {
      var child = element.childNodes[i]
      if (this.attemptFocus(child) || this.focusLastDescendant(child)) {
        return true
      }
    }
    return false
  },
  mounted() {
    this.beforeFocusEl = this.el.querySelector(".before-focus")
    this.beforeFocusEl.addEventListener("focus", () => this.beforeFocus())
    this.afterFocusEl = this.el.querySelector(".after-focus")
    this.afterFocusEl.addEventListener("focus", () => this.afterFocus())
    this.el.addEventListener("phx:show-end", () => this.show())
    if (window.getComputedStyle(this.el).display !== "none") {
      this.show()
    }
  },
  destroyed() {
    this.beforeFocusEl.removeEventListener("focus", () => this.beforeFocus())
    this.afterFocusEl.removeEventListener("focus", () => this.afterFocus())
    if (lastFocusedElement) {
      lastFocusedElement.focus()
    }
  },
  show() {
    this.el.focus()
  },
  beforeFocus() {
    this.focusLastDescendant(this.el)
  },
  afterFocus() {
    this.focusFirstDescendant(this.el)
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken}
})

let lastFocusedElement = null

let routeUpdated = () => {
  let target;
  if (lastFocusedElement != null) {
    lastFocusedElement = null
    return
  } else if (document.location.pathname.endsWith("/songs/new")) {
    lastFocusedElement = document.activeElement
    return
  } else {
    target = document.querySelector("main h1") || document.querySelector("main")
  }
  if (target) {
    let origTabIndex = target.getAttribute("tabindex")
    target.setAttribute("tabindex", "-1")
    target.focus()
    window.setTimeout(() => {
      if (origTabIndex) {
        target.setAttribute("tabindex", origTabIndex)
      } else {
        target.removeAttribute("tabindex")
      }
    }, 1000)
  }
}

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// Accessible routing
window.addEventListener("phx:page-loading-stop", () => window.requestAnimationFrame(() => window.requestAnimationFrame(routeUpdated)))

window.addEventListener("js:exec", e => e.target[e.detail.call](...e.detail.args))

// connect if there are any LiveViews on the page
liveSocket.getSocket().onOpen(() => execJS("#connection-status", "js-hide"))
liveSocket.getSocket().onError(() => execJS("#connection-status", "js-show"))
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


