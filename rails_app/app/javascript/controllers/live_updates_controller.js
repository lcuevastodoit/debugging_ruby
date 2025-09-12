import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "points", "level", "streak", "leaderboard"]
  static values = {
    pollInterval: { type: Number, default: 3000 },
    lastUpdate: String
  }

  connect() {
    console.log("Live updates controller connected")
    this.startPolling()
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.stopPolling() // Clear any existing interval

    this.pollTimer = setInterval(() => {
      this.fetchUpdates()
    }, this.pollIntervalValue)
  }

  stopPolling() {
    if (this.pollTimer) {
      clearInterval(this.pollTimer)
      this.pollTimer = null
    }
  }

  async fetchUpdates() {
    try {
      const response = await fetch('/debugging_game/live_status', {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.updateDisplay(data)
      }
    } catch (error) {
      console.error('Failed to fetch live updates:', error)
    }
  }

  updateDisplay(data) {
    // Only update if data has actually changed
    if (data.updated_at !== this.lastUpdateValue) {
      this.lastUpdateValue = data.updated_at

      // Update points
      if (this.hasPointsTarget) {
        this.pointsTarget.textContent = data.total_points
        this.animateChange(this.pointsTarget)
      }

      // Update level
      if (this.hasLevelTarget) {
        this.levelTarget.innerHTML = `${data.level_emoji} ${data.level_title}`
        this.animateChange(this.levelTarget)
      }

      // Update streak
      if (this.hasStreakTarget) {
        this.streakTarget.textContent = data.current_streak
        this.animateChange(this.streakTarget)
      }

      // Update status display
      if (this.hasStatusTarget) {
        this.statusTarget.innerHTML = `
          <div class="flex items-center space-x-4 text-sm text-gray-600">
            <span>📊 ${data.total_points} points</span>
            <span>🔥 ${data.current_streak} streak</span>
            <span>✅ ${data.completed_objectives_count} completed</span>
          </div>
        `
      }
    }
  }

  animateChange(element) {
    element.classList.add('animate-pulse')
    setTimeout(() => {
      element.classList.remove('animate-pulse')
    }, 1000)
  }

  // Manual refresh triggered by user
  refresh() {
    this.fetchUpdates()
  }

  // Toggle polling on/off
  togglePolling() {
    if (this.pollTimer) {
      this.stopPolling()
      console.log("Live updates paused")
    } else {
      this.startPolling()
      console.log("Live updates resumed")
    }
  }
}
