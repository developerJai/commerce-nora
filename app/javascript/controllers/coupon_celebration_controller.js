import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { amount: String }

  connect() {
    this.showCelebration()
  }

  showCelebration() {
    this.injectStyles()
    this.createConfettiCanvas()
    this.createSavingsBanner()

    // Auto-remove the stimulus element after animation completes
    setTimeout(() => {
      this.element.remove()
    }, 4500)
  }

  injectStyles() {
    if (document.getElementById("confetti-celebration-styles")) return

    const style = document.createElement("style")
    style.id = "confetti-celebration-styles"
    style.textContent = `
      @keyframes confetti-drift-down {
        0% {
          transform: translateY(-20px) translateX(0) rotateZ(0deg) rotateY(0deg) scaleY(1);
          opacity: 0;
        }
        5% {
          opacity: 1;
        }
        25% {
          transform: translateY(25vh) translateX(var(--drift-x1)) rotateZ(var(--spin1)) rotateY(180deg) scaleY(1.1);
        }
        50% {
          transform: translateY(50vh) translateX(var(--drift-x2)) rotateZ(var(--spin2)) rotateY(360deg) scaleY(0.9);
        }
        75% {
          transform: translateY(75vh) translateX(var(--drift-x1)) rotateZ(var(--spin3)) rotateY(540deg) scaleY(1.05);
          opacity: 0.8;
        }
        100% {
          transform: translateY(105vh) translateX(var(--drift-x2)) rotateZ(var(--spin4)) rotateY(720deg) scaleY(1);
          opacity: 0;
        }
      }

      @keyframes confetti-wave-2 {
        0% {
          transform: translateY(-20px) translateX(0) rotateZ(0deg) rotateX(0deg);
          opacity: 0;
        }
        8% {
          opacity: 1;
        }
        30% {
          transform: translateY(30vh) translateX(var(--drift-x2)) rotateZ(var(--spin2)) rotateX(180deg);
        }
        60% {
          transform: translateY(60vh) translateX(var(--drift-x1)) rotateZ(var(--spin3)) rotateX(360deg);
          opacity: 0.7;
        }
        100% {
          transform: translateY(110vh) translateX(var(--drift-x2)) rotateZ(var(--spin4)) rotateX(540deg);
          opacity: 0;
        }
      }

      @keyframes banner-enter {
        0% {
          opacity: 0;
          transform: translate(-50%, -50%) scale(0.5) rotateX(20deg);
        }
        50% {
          opacity: 1;
          transform: translate(-50%, -50%) scale(1.05) rotateX(-2deg);
        }
        70% {
          transform: translate(-50%, -50%) scale(0.98) rotateX(1deg);
        }
        100% {
          opacity: 1;
          transform: translate(-50%, -50%) scale(1) rotateX(0deg);
        }
      }

      @keyframes banner-exit {
        0% {
          opacity: 1;
          transform: translate(-50%, -50%) scale(1);
        }
        100% {
          opacity: 0;
          transform: translate(-50%, -50%) scale(0.85) translateY(20px);
        }
      }

      @keyframes shimmer-sweep {
        0% { background-position: -200% center; }
        100% { background-position: 200% center; }
      }

      @keyframes glow-pulse {
        0%, 100% { box-shadow: 0 20px 60px rgba(5, 150, 105, 0.3), 0 0 0 0 rgba(16, 185, 129, 0.2); }
        50% { box-shadow: 0 25px 70px rgba(5, 150, 105, 0.45), 0 0 0 12px rgba(16, 185, 129, 0); }
      }

      @keyframes emoji-bounce {
        0%, 100% { transform: scale(1) rotate(0deg); }
        25% { transform: scale(1.2) rotate(-8deg); }
        50% { transform: scale(1.3) rotate(5deg); }
        75% { transform: scale(1.15) rotate(-3deg); }
      }
    `
    document.head.appendChild(style)
  }

  createConfettiCanvas() {
    const container = document.createElement("div")
    container.style.cssText = "position:fixed;inset:0;z-index:9999;pointer-events:none;overflow:hidden;"
    document.body.appendChild(container)

    const colors = [
      "#f59e0b", "#fbbf24", "#f97316", // amber/orange
      "#10b981", "#34d399", "#059669", // emerald/green
      "#f43f5e", "#fb7185", "#e11d48", // rose/red
      "#8b5cf6", "#a78bfa", "#7c3aed", // purple/violet
      "#06b6d4", "#22d3ee", "#0891b2", // cyan/teal
      "#ec4899", "#f472b6",            // pink
      "#eab308", "#facc15",            // yellow
    ]

    // Wave 1: main burst of ribbons and confetti
    this.spawnConfettiWave(container, colors, {
      count: 80,
      delay: 0,
      durationMin: 2.2,
      durationMax: 3.5,
      animation: "confetti-drift-down"
    })

    // Wave 2: secondary burst slightly delayed
    this.spawnConfettiWave(container, colors, {
      count: 50,
      delay: 0.3,
      durationMin: 2.5,
      durationMax: 3.8,
      animation: "confetti-wave-2"
    })

    // Wave 3: trailing light confetti
    this.spawnConfettiWave(container, colors, {
      count: 30,
      delay: 0.8,
      durationMin: 2.4,
      durationMax: 3.6,
      animation: "confetti-drift-down"
    })

    setTimeout(() => container.remove(), 5000)
  }

  spawnConfettiWave(container, colors, { count, delay, durationMin, durationMax, animation }) {
    for (let i = 0; i < count; i++) {
      const particle = document.createElement("div")
      const color = colors[Math.floor(Math.random() * colors.length)]
      const type = Math.random()

      // Randomize shape: ribbons (long thin), squares, circles, stars
      let width, height, borderRadius, extraStyles = ""

      if (type < 0.4) {
        // Ribbon / streamer — long colorful threads
        width = Math.random() * 6 + 4
        height = Math.random() * 28 + 16
        borderRadius = "3px"
      } else if (type < 0.65) {
        // Wider ribbon
        width = Math.random() * 10 + 7
        height = Math.random() * 18 + 10
        borderRadius = "2px"
      } else if (type < 0.8) {
        // Circle
        const size = Math.random() * 10 + 6
        width = size
        height = size
        borderRadius = "50%"
      } else if (type < 0.9) {
        // Square
        const size = Math.random() * 9 + 5
        width = size
        height = size
        borderRadius = "2px"
      } else {
        // Small dot / sparkle
        const size = Math.random() * 5 + 3
        width = size
        height = size
        borderRadius = "50%"
        extraStyles = `box-shadow: 0 0 ${size}px ${color};`
      }

      const x = Math.random() * 100
      const particleDelay = delay + Math.random() * 0.6
      const duration = Math.random() * (durationMax - durationMin) + durationMin
      const driftX1 = (Math.random() - 0.5) * 160
      const driftX2 = (Math.random() - 0.5) * 200
      const spin1 = Math.random() * 360
      const spin2 = spin1 + Math.random() * 360
      const spin3 = spin2 + Math.random() * 360
      const spin4 = spin3 + Math.random() * 360

      particle.style.cssText = `
        position: absolute;
        top: -30px;
        left: ${x}%;
        width: ${width}px;
        height: ${height}px;
        background: ${color};
        border-radius: ${borderRadius};
        opacity: 0;
        will-change: transform, opacity;
        animation: ${animation} ${duration}s cubic-bezier(0.25, 0.46, 0.45, 0.94) ${particleDelay}s forwards;
        --drift-x1: ${driftX1}px;
        --drift-x2: ${driftX2}px;
        --spin1: ${spin1}deg;
        --spin2: ${spin2}deg;
        --spin3: ${spin3}deg;
        --spin4: ${spin4}deg;
        ${extraStyles}
      `

      container.appendChild(particle)
    }
  }

  createSavingsBanner() {
    const overlay = document.createElement("div")
    overlay.style.cssText = `
      position: fixed;
      inset: 0;
      z-index: 10000;
      pointer-events: none;
      background: rgba(0, 0, 0, 0);
      transition: background 0.5s ease;
    `
    // Fade in the dark overlay
    requestAnimationFrame(() => {
      overlay.style.background = "rgba(0, 0, 0, 0.25)"
    })

    const banner = document.createElement("div")
    banner.style.cssText = `
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%) scale(0.5);
      z-index: 10000;
      pointer-events: none;
      opacity: 0;
      perspective: 600px;
      animation: banner-enter 0.5s cubic-bezier(0.34, 1.56, 0.64, 1) 0.2s forwards;
    `

    banner.innerHTML = `
      <div style="
        background: linear-gradient(145deg, #064e3b, #047857, #065f46);
        border-radius: 24px;
        padding: 32px 48px;
        text-align: center;
        animation: glow-pulse 1.5s ease-in-out infinite;
        border: 1px solid rgba(167, 243, 208, 0.2);
        position: relative;
        overflow: hidden;
      ">
        <div style="
          position: absolute;
          inset: 0;
          background: linear-gradient(90deg, transparent, rgba(255,255,255,0.08), transparent);
          background-size: 200% 100%;
          animation: shimmer-sweep 2s ease-in-out infinite;
          border-radius: 24px;
        "></div>
        <div style="position: relative; z-index: 1;">
          <div style="font-size: 40px; margin-bottom: 8px; animation: emoji-bounce 1s ease-in-out 0.5s 2;">🎉</div>
          <div style="color: #a7f3d0; font-size: 11px; font-weight: 700; letter-spacing: 2px; text-transform: uppercase; margin-bottom: 8px;">Congratulations!</div>
          <div style="color: #d1fae5; font-size: 13px; font-weight: 600; letter-spacing: 0.5px; margin-bottom: 4px;">You saved</div>
          <div style="
            color: #ffffff;
            font-size: 34px;
            font-weight: 800;
            line-height: 1.1;
            background: linear-gradient(135deg, #ffffff, #a7f3d0);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
          ">${this.amountValue}</div>
          <div style="color: #6ee7b7; font-size: 12px; margin-top: 10px; font-weight: 500;">Coupon applied successfully!</div>
        </div>
      </div>
    `

    document.body.appendChild(overlay)
    document.body.appendChild(banner)

    // Animate out smoothly
    setTimeout(() => {
      banner.style.animation = "banner-exit 0.5s ease-in forwards"
      overlay.style.background = "rgba(0, 0, 0, 0)"
      setTimeout(() => {
        banner.remove()
        overlay.remove()
      }, 500)
    }, 2800)
  }
}
