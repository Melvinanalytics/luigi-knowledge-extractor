import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { startTime: String }

  connect() {
    this.startTimer()
  }

  disconnect() {
    this.stopTimer()
  }

  startTimer() {
    this.startTime = new Date(this.startTimeValue)
    this.updateTimer()
    
    this.timerInterval = setInterval(() => {
      this.updateTimer()
    }, 1000)
  }

  stopTimer() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
    }
  }

  updateTimer() {
    const now = new Date()
    const elapsed = Math.floor((now - this.startTime) / 1000)
    
    const hours = Math.floor(elapsed / 3600)
    const minutes = Math.floor((elapsed % 3600) / 60)
    const seconds = elapsed % 60
    
    let formattedTime
    if (hours > 0) {
      formattedTime = `${hours}h ${minutes}m ${seconds}s`
    } else if (minutes > 0) {
      formattedTime = `${minutes}m ${seconds}s`
    } else {
      formattedTime = `${seconds}s`
    }
    
    this.element.textContent = formattedTime
  }
}