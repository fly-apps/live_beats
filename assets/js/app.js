import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "./phoenix_live_view"
import topbar from "../vendor/topbar"

let nowSeconds = () => Math.round(Date.now() / 1000)

let Hooks = {}

Hooks.Progress = {
	setWidth(at){
		this.el.style.width = `${Math.floor((at / (this.max - this.min)) * 100)}%`
	},
	mounted(){
		this.min = parseInt(this.el.dataset.min)
		this.max = parseInt(this.el.dataset.max)
		this.val = parseInt(this.el.dataset.val)
		setInterval(() => this.setWidth(this.val++), 1000)
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
      document.removeEventListener("click", enableAudio)
      this.player.play().catch(error => null)
      this.player.pause()
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
    this.handleEvent("pause", () => {
      this.pause()
    })
  },

  play(opts = {}){
    let {sync} = opts
    this.player.play().then(() => {
      if(sync){ this.player.currentTime = nowSeconds() - this.playbackBeganAt }
      this.progressTimer = setInterval(() => this.updateProgress(), 100)
      this.pushEvent("audio-accepted", {})
    }, error => {
      this.pushEvent("audio-rejected", {})
    })
  },

  pause(){
    clearInterval(this.progressTimer)
    this.player.pause()
  },

  updateProgress(){
    if(isNaN(this.player.duration)){ return false }
		this.progress.style.width = `${(this.player.currentTime / (this.player.duration) * 100)}%`
    this.duration.innerText = this.formatTime(this.player.duration)
    this.currentTime.innerText = this.formatTime(this.player.currentTime)
  },

  formatTime(seconds){ return new Date(1000 * seconds).toISOString().substr(14, 5) }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
	hooks: Hooks,
  params: {_csrf_token: csrfToken},
  dom: {
    onNodeAdded(node){
      if(node.getAttribute && node.getAttribute("data-fade-in")){
        from.classList.add("fade-in")
      }
    },
    onBeforeElUpdated(from, to) {
      if(from.classList.contains("fade-in")){
        from.classList.remove("fade-in")
        from.classList.add("fade-in")
      }
    }
  }
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
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


