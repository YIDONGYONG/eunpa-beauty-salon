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
    // キーが無効・URL 未登録のとき NAVER が呼ぶ関数。代わりの表示（地図画像）に切り替える
    window.navermap_authFailure = () => this.showFallback()
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
      zoom: 17, // 少し近め（お年寄りにも建物が見分けやすい）
      scaleControl: false,
      mapDataControl: false,
      zoomControl: true,
      zoomControlOptions: { position: naver.maps.Position.TOP_RIGHT }
    })
    // 大きな丸いピン + 店名ラベル（小さな標準ピンだと見つけにくい）。店名は HTML エスケープして埋め込む
    const label = this.titleValue.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c])
    new naver.maps.Marker({
      position, map, title: this.titleValue,
      icon: { content: `<div class="map-pin"><span class="map-pin-label">${label}</span><span class="map-pin-dot"></span></div>`, anchor: new naver.maps.Point(14, 14) }
    })
  }

  showFallback() {
    this.canvasTarget.hidden = true
    this.fallbackTarget.hidden = false
  }
}
