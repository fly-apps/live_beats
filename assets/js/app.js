import "phoenix_html"
import { Socket } from "phoenix"
// import {LiveSocket} from "./phoenix_live_view"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

let nowSeconds = () => Math.round(Date.now() / 1000)

let execJS = (selector, attr) => {
  document.querySelectorAll(selector).forEach(el => liveSocket.execJS(el, el.getAttribute(attr)))
}

let Hooks = {}

Hooks.Menu = {
  getAttr(name) {
    let val = this.el.getAttribute(name)
    if (val === null) { throw (new Error(`no ${name} attribute configured for menu`)) }
    return val
  },
  reset() {
    this.activeClass = this.getAttr("data-active-class")
    this.deactivate(this.menuItems())
    this.activeItem = null
  },
  mounted() {
    this.menuItemsContainer = document.querySelector(`[aria-labelledby="${this.el.id}"]`)
    this.reset()
    this.el.addEventListener("click", e => {
      if (e.currentTarget.isSameNode(this.el)) {
        requestAnimationFrame(() => this.activate(0))
      }
    })
    document.addEventListener("keydown", e => {
      if (this.activeItem) {
        e.preventDefault()
        if (e.key === "Escape") {
          document.body.click()
          this.reset()
          this.el.focus()
        } else if (e.key === "Enter") {
          this.activeItem.click()
        } else if (e.key === "ArrowDown") {
          let menuItems = this.menuItems()
          let index = menuItems.indexOf(this.activeItem)
          this.deactivate(menuItems)
          this.activate(index + 1, 0)
        } else if (e.key === "ArrowUp") {
          let menuItems = this.menuItems()
          let index = menuItems.indexOf(this.activeItem)
          this.deactivate(menuItems)
          this.activate(index - 1, menuItems.length - 1)
        }
      }
    })
  },
  activate(index, fallbackIndex) {
    let menuItems = this.menuItems()
    this.activeItem = menuItems[index] || menuItems[fallbackIndex]
    this.activeItem.classList.add(this.activeClass)
    this.activeItem.focus()
  },
  deactivate(items) { items.forEach(item => item.classList.remove(this.activeClass)) },
  menuItems() { return Array.from(this.menuItemsContainer.querySelectorAll("[role=menuitem]")) }
}

Hooks.Flash = {
  mounted() {
    let hide = () => this.el.click()
    let timer = setTimeout(() => hide(), 8000)
    this.el.addEventListener("mouseover", () => {
      clearTimeout(timer)
      timer = setTimeout(() => hide(), 8000)
    })
  }
}

Hooks.AudioPlayer = {
  mounted() {
    this.playbackBeganAt = null
    this.player = this.el.querySelector("audio")
    this.currentTime = this.el.querySelector("#player-time")
    this.duration = this.el.querySelector("#player-duration")
    this.progress = this.el.querySelector("#player-progress")
    let enableAudio = () => {
      if (this.player.src) {
        document.removeEventListener("click", enableAudio)
        if (this.player.readyState === 0) {
          this.player.play().catch(error => null)
          this.player.pause()
        }
      }
    }
    document.addEventListener("click", enableAudio)
    this.el.addEventListener("js:listen_now", () => this.play({ sync: true }))
    this.el.addEventListener("js:play_pause", () => {
      if (this.player.paused) {
        this.play()
      }
    })
    this.handleEvent("play", ({ url, token, elapsed }) => {
      this.playbackBeganAt = nowSeconds() - elapsed
      let currentSrc = this.player.src.split("?")[0]
      if (currentSrc === url && this.player.paused) {
        this.play({ sync: true })
      } else if (currentSrc !== url) {
        this.player.src = `${url}?token=${token}`
        this.play({ sync: true })
      }
    })
    this.handleEvent("pause", () => this.pause())
    this.handleEvent("stop", () => this.stop())
  },

  play(opts = {}) {
    let { sync } = opts
    this.player.play().then(() => {
      if (sync) { this.player.currentTime = nowSeconds() - this.playbackBeganAt }
      this.progressTimer = setInterval(() => this.updateProgress(), 100)
    }, error => {
      if (error.name === "NotAllowedError") {
        execJS("#enable-audio", "data-js-show")
      }
    })
  },

  pause() {
    clearInterval(this.progressTimer)
    this.player.pause()
  },

  stop() {
    clearInterval(this.progressTimer)
    this.player.pause()
    this.player.currentTime = 0
    this.updateProgress()
    this.duration.innerText = ""
    this.currentTime.innerText = ""
  },

  updateProgress() {
    if (isNaN(this.player.duration)) { return false }
    if (this.player.currentTime >= this.player.duration) {
      this.pushEvent("next_song_auto")
      clearInterval(this.progressTimer)
      return
    }
    this.progress.style.width = `${(this.player.currentTime / (this.player.duration) * 100)}%`
    this.duration.innerText = this.formatTime(this.player.duration)
    this.currentTime.innerText = this.formatTime(this.player.currentTime)
  },

  formatTime(seconds) { return new Date(1000 * seconds).toISOString().substr(14, 5) }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken }
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

window.addEventListener("js:exec", e => e.target[e.detail.call](...e.detail.args))

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


