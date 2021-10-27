import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "./phoenix_live_view"
import topbar from "../vendor/topbar"

let render = (webComponent, html) => {
	let shadow = webComponent.attachShadow({mode: "open"})
	document.querySelectorAll("link").forEach(link => shadow.appendChild(link.cloneNode()))
  let div = document.createElement("div")
	div.setAttribute("class", webComponent.getAttribute("class"))
	div.innerHTML = html || webComponent.innerHTML
  shadow.appendChild(div)
	return div
}

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

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


