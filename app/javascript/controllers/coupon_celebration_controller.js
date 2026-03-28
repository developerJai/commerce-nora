import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { amount: String }

  connect() {
    this.showCelebration()
  }

  showCelebration() {
    this.createSparkles()
    this.createSavingsBanner()

    // Auto-remove the entire element after animation completes
    setTimeout(() => {
      this.element.remove()
    }, 3500)
  }

  createSparkles() {
    const container = document.createElement("div")
    container.style.cssText = "position:fixed;inset:0;z-index:9999;pointer-events:none;overflow:hidden"
    document.body.appendChild(container)

    const colors = ["#f59e0b", "#10b981", "#f43f5e", "#8b5cf6", "#06b6d4", "#fbbf24", "#34d399"]
    const shapes = ["circle", "square", "star"]

    for (let i = 0; i < 60; i++) {
      const particle = document.createElement("div")
      const color = colors[Math.floor(Math.random() * colors.length)]
      const shape = shapes[Math.floor(Math.random() * shapes.length)]
      const size = Math.random() * 8 + 4
      const x = Math.random() * 100
      const delay = Math.random() * 0.6
      const duration = Math.random() * 1.2 + 1.5
      const drift = (Math.random() - 0.5) * 120

      particle.style.cssText = `
        position:absolute;
        top:-12px;
        left:${x}%;
        width:${size}px;
        height:${size}px;
        background:${color};
        opacity:0;
        border-radius:${shape === "circle" ? "50%" : shape === "square" ? "2px" : "0"};
        animation:confetti-fall ${duration}s ease-out ${delay}s forwards;
        --drift:${drift}px;
      `

      if (shape === "star") {
        particle.style.background = "none"
        particle.innerHTML = `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="${color}"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>`
      }

      container.appendChild(particle)
    }

    // Inject animation keyframes if not already present
    if (!document.getElementById("confetti-styles")) {
      const style = document.createElement("style")
      style.id = "confetti-styles"
      style.textContent = `
        @keyframes confetti-fall {
          0% { transform:translateY(0) translateX(0) rotate(0deg) scale(1); opacity:1; }
          80% { opacity:1; }
          100% { transform:translateY(100vh) translateX(var(--drift)) rotate(${360 + Math.random() * 360}deg) scale(0.3); opacity:0; }
        }
      `
      document.head.appendChild(style)
    }

    setTimeout(() => container.remove(), 3600)
  }

  createSavingsBanner() {
    const banner = document.createElement("div")
    banner.style.cssText = `
      position:fixed;
      top:50%;
      left:50%;
      transform:translate(-50%,-50%) scale(0.3);
      z-index:10000;
      pointer-events:none;
      opacity:0;
      transition:all 0.4s cubic-bezier(0.34,1.56,0.64,1);
    `
    banner.innerHTML = `
      <div style="background:linear-gradient(135deg,#065f46,#047857);border-radius:20px;padding:24px 36px;text-align:center;box-shadow:0 25px 60px rgba(0,0,0,0.3);">
        <div style="font-size:28px;margin-bottom:4px;">🎉</div>
        <div style="color:#d1fae5;font-size:12px;font-weight:600;letter-spacing:1px;text-transform:uppercase;margin-bottom:6px;">You saved</div>
        <div style="color:#ffffff;font-size:28px;font-weight:800;line-height:1;">${this.amountValue}</div>
        <div style="color:#a7f3d0;font-size:11px;margin-top:6px;">Coupon applied successfully!</div>
      </div>
    `

    document.body.appendChild(banner)

    // Animate in
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        banner.style.opacity = "1"
        banner.style.transform = "translate(-50%,-50%) scale(1)"
      })
    })

    // Animate out
    setTimeout(() => {
      banner.style.opacity = "0"
      banner.style.transform = "translate(-50%,-50%) scale(0.8)"
      setTimeout(() => banner.remove(), 400)
    }, 2500)
  }
}
