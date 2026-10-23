import { Controller } from "@hotwired/stimulus"

// NAVER 地図（Naver Maps JavaScript API v3）。Client ID は環境変数 NAVER_MAP_CLIENT_ID。
export default class extends Controller {
  static targets = ["canvas", "fallback"]
  static values = { clientId: String, lat: Number, lng: Number, title: String }

  connect() {
    if (!this.clientIdValue || !this.latValue || !this.lngValue) return this.showFallback()

    this.loadScript()
      .then(() => this.render())
      .catch(() => this.showFallback())
  }

  loadScript() {
    if (window.naver && window.naver.maps) return Promise.resolve()
    return new Promise((resolve, reject) => {
      const script = document.createElement("script")
      script.src = `https://oapi.map.naver.com/openapi/v3/maps.js?ncpKeyId=${encodeURIComponent(this.clientIdValue)}`
      script.async = true
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })
  }

  render() {
    const position = new naver.maps.LatLng(this.latValue, this.lngValue)
    const map = new naver.maps.Map(this.canvasTarget, {
      center: position,
      zoom: 16,
      scaleControl: false,
      mapDataControl: false,
      zoomControl: true,
      zoomControlOptions: { position: naver.maps.Position.TOP_RIGHT }
    })
    new naver.maps.Marker({ position, map, title: this.titleValue })
  }

  showFallback() {
    this.canvasTarget.hidden = true
    this.fallbackTarget.hidden = false
  }
}
