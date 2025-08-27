import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  selectQuestion(event) {
    const question = event.currentTarget.dataset.question
    const textareaElement = document.querySelector('[data-message-form-target="textarea"]')
    
    if (textareaElement && question) {
      textareaElement.value = question
      textareaElement.focus()
      
      // Trigger input event for character counter and auto-resize
      textareaElement.dispatchEvent(new Event('input'))
      
      // Auto-scroll to bottom
      textareaElement.scrollIntoView({ behavior: 'smooth', block: 'center' })
      
      // Visual feedback
      event.currentTarget.style.transform = 'scale(0.95)'
      event.currentTarget.style.backgroundColor = 'rgba(59, 130, 246, 0.3)'
      
      setTimeout(() => {
        event.currentTarget.style.transform = ''
        event.currentTarget.style.backgroundColor = ''
      }, 200)
    }
  }
}