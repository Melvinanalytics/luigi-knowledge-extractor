import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "submitButton", "characterCounter", "typingIndicator"]
  
  connect() {
    this.textareaTarget.focus()
    this.updateCharacterCount()
    this.setupAutoResize()
  }

  handleKeydown(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      this.submitForm()
    } else if (event.key === 'Tab') {
      event.preventDefault()
      this.insertText('    ') // Insert 4 spaces for tab
    }
  }

  handleInput(event) {
    this.updateCharacterCount()
    this.autoResize()
    this.handleTyping()
  }

  submitForm() {
    const content = this.textareaTarget.value.trim()
    if (content === '') return

    // Try to send via WebSocket first
    const sessionController = this.getSessionController()
    if (sessionController && sessionController.sendMessage(content)) {
      this.clearForm()
      return
    }

    // Fallback to form submission
    this.element.requestSubmit()
  }

  clearForm() {
    this.textareaTarget.value = ''
    this.textareaTarget.focus()
    this.updateCharacterCount()
    this.autoResize()
  }

  insertTemplate(event) {
    const template = event.currentTarget.dataset.template
    if (template) {
      this.insertText(template)
    }
  }

  insertText(text) {
    const textarea = this.textareaTarget
    const start = textarea.selectionStart
    const end = textarea.selectionEnd
    const currentValue = textarea.value

    textarea.value = currentValue.slice(0, start) + text + currentValue.slice(end)
    textarea.selectionStart = textarea.selectionEnd = start + text.length
    textarea.focus()
    
    this.updateCharacterCount()
    this.autoResize()
  }

  updateCharacterCount() {
    if (this.hasCharacterCounterTarget) {
      const count = this.textareaTarget.value.length
      this.characterCounterTarget.textContent = `${count} Zeichen`
      
      // Color coding for length
      if (count > 1000) {
        this.characterCounterTarget.className = 'text-red-300'
      } else if (count > 500) {
        this.characterCounterTarget.className = 'text-yellow-300'
      } else {
        this.characterCounterTarget.className = 'text-blue-300'
      }
    }
  }

  setupAutoResize() {
    this.originalHeight = this.textareaTarget.scrollHeight
    this.autoResize()
  }

  autoResize() {
    const textarea = this.textareaTarget
    textarea.style.height = 'auto'
    
    const newHeight = Math.max(textarea.scrollHeight, this.originalHeight)
    const maxHeight = 200 // Maximum height in pixels
    
    textarea.style.height = Math.min(newHeight, maxHeight) + 'px'
    textarea.style.overflowY = newHeight > maxHeight ? 'auto' : 'hidden'
  }

  handleTyping() {
    // Debounce typing indicator
    clearTimeout(this.typingTimeout)
    
    if (!this.isTyping) {
      this.isTyping = true
      this.sendTypingStart()
    }
    
    this.typingTimeout = setTimeout(() => {
      this.isTyping = false
      this.sendTypingStop()
    }, 1000)
  }

  sendTypingStart() {
    const sessionController = this.getSessionController()
    if (sessionController && sessionController.subscription) {
      sessionController.subscription.perform('typing_start')
    }
  }

  sendTypingStop() {
    const sessionController = this.getSessionController()
    if (sessionController && sessionController.subscription) {
      sessionController.subscription.perform('typing_stop')
    }
  }

  getSessionController() {
    const sessionElement = document.querySelector('[data-controller*="luigi-session"]')
    if (sessionElement) {
      return this.application.getControllerForElementAndIdentifier(
        sessionElement,
        'luigi-session'
      )
    }
    return null
  }

  // Handle form submission completion
  clearForm() {
    this.textareaTarget.value = ''
    this.textareaTarget.focus()
    this.updateCharacterCount()
    this.autoResize()
    
    // Enable submit button if it was disabled
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false
    }
  }

  // Disable form during submission
  beforeSubmit() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
    }
  }

  // Handle form errors
  handleError(error) {
    console.error('Message form error:', error)
    
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false
    }
    
    // Show error notification
    const sessionController = this.getSessionController()
    if (sessionController) {
      sessionController.showError('Nachricht konnte nicht gesendet werden')
    }
  }

  // Paste handling for images/files
  handlePaste(event) {
    const items = Array.from(event.clipboardData?.items || [])
    const imageItem = items.find(item => item.type.startsWith('image/'))
    
    if (imageItem) {
      event.preventDefault()
      const file = imageItem.getAsFile()
      this.handleImagePaste(file)
    }
  }

  handleImagePaste(file) {
    // For future image support
    console.log('Image pasted:', file.name)
    
    const sessionController = this.getSessionController()
    if (sessionController) {
      sessionController.showNotification('📷 Bildupload noch nicht unterstützt', 'info')
    }
  }

  // Quick emoji insertion
  insertEmoji(event) {
    const emoji = event.currentTarget.dataset.emoji
    if (emoji) {
      this.insertText(emoji)
    }
  }

  // Template shortcuts
  handleShortcut(event) {
    if (event.ctrlKey || event.metaKey) {
      switch (event.key) {
        case '1':
          event.preventDefault()
          this.insertText('Ich hab da mal ein Problem mit ')
          break
        case '2':
          event.preventDefault()
          this.insertText('Bei Projekten wie ')
          break
        case '3':
          event.preventDefault()
          this.insertText('Meine Erfahrung zeigt ')
          break
        case 'Enter':
          event.preventDefault()
          this.submitForm()
          break
      }
    }
  }
}