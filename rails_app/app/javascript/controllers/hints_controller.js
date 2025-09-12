import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "content", "counter"]
  static values = { objectiveKey: String }

  connect() {
    console.log("Hints controller connected for objective:", this.objectiveKeyValue)
  }

  async requestHint() {
    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = "Loading..."

    try {
      const response = await fetch('/debugging_game/get_hint', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          objective_key: this.objectiveKeyValue
        })
      })

      const data = await response.json()

      if (response.ok) {
        this.displayHint(data)
        this.updateHintCounter(data.hints_used)
      } else {
        this.displayError(data.error)
      }
    } catch (error) {
      console.error('Error fetching hint:', error)
      this.displayError('Failed to load hint. Please try again.')
    } finally {
      this.buttonTarget.disabled = false
      this.buttonTarget.textContent = "💡 Get Hint"
    }
  }

  displayHint(data) {
    this.contentTarget.innerHTML = `
      <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mt-4">
        <div class="flex items-start space-x-3">
          <span class="text-2xl">💡</span>
          <div class="flex-1">
            <h4 class="font-medium text-yellow-800 mb-2">Hint ${data.hints_used}</h4>
            <p class="text-yellow-700">${data.hint}</p>
            ${data.penalty_points > 0 ? `
              <p class="text-xs text-yellow-600 mt-2">
                <strong>Note:</strong> Using hints reduces your final score by ${data.penalty_points} points
              </p>
            ` : ''}
          </div>
        </div>
      </div>
    `
    
    // Animate the hint appearance
    this.contentTarget.firstElementChild.style.opacity = '0'
    this.contentTarget.firstElementChild.style.transform = 'translateY(-10px)'
    
    setTimeout(() => {
      this.contentTarget.firstElementChild.style.transition = 'all 0.3s ease-out'
      this.contentTarget.firstElementChild.style.opacity = '1'
      this.contentTarget.firstElementChild.style.transform = 'translateY(0)'
    }, 10)
  }

  displayError(error) {
    this.contentTarget.innerHTML = `
      <div class="bg-red-50 border border-red-200 rounded-lg p-4 mt-4">
        <div class="flex items-center space-x-2">
          <span class="text-xl">❌</span>
          <p class="text-red-700">${error}</p>
        </div>
      </div>
    `
  }

  updateHintCounter(hintsUsed) {
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = hintsUsed
      this.counterTarget.classList.add('animate-pulse')
      setTimeout(() => {
        this.counterTarget.classList.remove('animate-pulse')
      }, 1000)
    }
  }

  clearHint() {
    this.contentTarget.innerHTML = ''
  }
}
