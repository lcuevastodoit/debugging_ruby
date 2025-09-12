import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["notification", "progressBar", "card"]

  connect() {
    console.log("UI enhancements controller connected")
    this.setupIntersectionObserver()
    this.setupAutoHideNotifications()
  }

  setupIntersectionObserver() {
    // Animate cards when they come into view
    if (this.hasCardTarget && 'IntersectionObserver' in window) {
      const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            entry.target.classList.add('animate-fade-in-up')
          }
        })
      }, { threshold: 0.1 })

      this.cardTargets.forEach(card => {
        observer.observe(card)
      })
    }
  }

  setupAutoHideNotifications() {
    // Auto-hide notifications after 10 seconds
    if (this.hasNotificationTarget) {
      this.notificationTargets.forEach(notification => {
        setTimeout(() => {
          this.hideNotification(notification)
        }, 10000)
      })
    }
  }

  hideNotification(notification) {
    notification.style.transition = 'all 0.3s ease-out'
    notification.style.opacity = '0'
    notification.style.transform = 'translateX(100%)'

    setTimeout(() => {
      if (notification.parentNode) {
        notification.remove()
      }
    }, 300)
  }

  dismissNotification(event) {
    const notification = event.target.closest('[data-ui-enhancements-target="notification"]')
    if (notification) {
      this.hideNotification(notification)
    }
  }

  animateProgressBar() {
    if (this.hasProgressBarTarget) {
      this.progressBarTargets.forEach(bar => {
        const width = bar.dataset.width || '0%'
        bar.style.width = '0%'

        setTimeout(() => {
          bar.style.transition = 'width 1s ease-out'
          bar.style.width = width
        }, 100)
      })
    }
  }

  showTooltip(event) {
    const tooltip = event.target.dataset.tooltip
    if (tooltip) {
      this.createTooltip(event.target, tooltip)
    }
  }

  hideTooltip(event) {
    const existingTooltip = document.querySelector('.custom-tooltip')
    if (existingTooltip) {
      existingTooltip.remove()
    }
  }

  createTooltip(element, text) {
    const tooltip = document.createElement('div')
    tooltip.className = 'custom-tooltip absolute z-50 bg-gray-800 text-white text-xs rounded px-2 py-1 pointer-events-none'
    tooltip.textContent = text

    document.body.appendChild(tooltip)

    const rect = element.getBoundingClientRect()
    tooltip.style.left = rect.left + (rect.width / 2) - (tooltip.offsetWidth / 2) + 'px'
    tooltip.style.top = rect.top - tooltip.offsetHeight - 5 + 'px'

    setTimeout(() => tooltip.remove(), 3000)
  }
}
