import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = [
    "timer", "stats", "entitiesCount", "relationshipsCount", 
    "messagesCount", "confidence", "messagesContainer",
    "processingIndicator", "connectionStatus", "messageForm",
    "voiceInterface", "voiceButton", "audioInput"
  ]
  static values = { sessionId: String }

  connect() {
    console.log("Luigi Session connected", this.sessionIdValue)
    
    this.setupActionCable()
    this.startTimer()
    this.scrollToBottom()
    this.showConnectionStatus("Verbindung wird aufgebaut...", "connecting")
  }

  disconnect() {
    this.teardownActionCable()
    this.stopTimer()
  }

  setupActionCable() {
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { 
        channel: "LuigiSessionChannel", 
        session_id: this.sessionIdValue 
      },
      {
        received: (data) => this.handleMessage(data),
        connected: () => this.handleConnectionEstablished(),
        disconnected: () => this.handleConnectionLost()
      }
    )
  }

  teardownActionCable() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
    if (this.consumer) {
      this.consumer.disconnect()
      this.consumer = null
    }
  }

  handleConnectionEstablished() {
    console.log("WebSocket connection established")
    this.showConnectionStatus("Verbunden", "connected")
    setTimeout(() => this.hideConnectionStatus(), 3000)
  }

  handleConnectionLost() {
    console.log("WebSocket connection lost")
    this.showConnectionStatus("Verbindung unterbrochen", "disconnected")
  }

  startTimer() {
    // Timer updates every second
    this.timerInterval = setInterval(() => {
      if (this.hasTimerTarget) {
        // Timer is updated by server, but we could add client-side updates here
      }
    }, 1000)
  }

  stopTimer() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
    }
  }

  handleMessage(data) {
    console.log("Received WebSocket message:", data.type, data)
    
    switch(data.type) {
      case 'connection_established':
        this.updateStats(data.session_stats)
        break
        
      case 'message_sent':
        this.addMessageToChat(data.message)
        if (data.processing) {
          this.showProcessingIndicator()
        }
        break
        
      case 'processing_started':
        this.showProcessingIndicator()
        break
        
      case 'extraction_complete':
        this.hideProcessingIndicator()
        this.addMessageToChat(data.assistant_message)
        this.updateStats(data.session_stats)
        this.showKnowledgeExtractedNotification(data.entities_count, data.confidence)
        break
        
      case 'extraction_error':
        this.hideProcessingIndicator()
        this.addMessageToChat(data.error_message)
        this.showError("Wissensextraktion fehlgeschlagen")
        break
        
      case 'typing_start':
        this.showTypingIndicator()
        break
        
      case 'typing_stop':
        this.hideTypingIndicator()
        break
    }
  }

  addMessageToChat(messageHtml) {
    if (this.hasMessagesContainerTarget) {
      this.messagesContainerTarget.insertAdjacentHTML('beforeend', messageHtml)
      this.scrollToBottom()
    }
  }

  showProcessingIndicator() {
    if (this.hasProcessingIndicatorTarget) {
      this.processingIndicatorTarget.classList.remove('hidden')
      this.scrollToBottom()
    }
  }

  hideProcessingIndicator() {
    if (this.hasProcessingIndicatorTarget) {
      this.processingIndicatorTarget.classList.add('hidden')
    }
  }

  updateStats(stats) {
    if (this.hasEntitiesCountTarget) {
      this.animateCounterUpdate(this.entitiesCountTarget, stats.entities_extracted)
    }
    if (this.hasRelationshipsCountTarget) {
      this.animateCounterUpdate(this.relationshipsCountTarget, stats.relationships_created)
    }
    if (this.hasMessagesCountTarget) {
      this.animateCounterUpdate(this.messagesCountTarget, stats.total_messages)
    }
    if (this.hasConfidenceTarget) {
      this.animateCounterUpdate(this.confidenceTarget, Math.round(stats.avg_confidence * 100) + '%')
    }
  }

  animateCounterUpdate(element, newValue) {
    element.style.transform = 'scale(1.1)'
    element.style.color = '#10B981' // green
    element.textContent = newValue
    
    setTimeout(() => {
      element.style.transform = 'scale(1)'
      element.style.color = ''
    }, 300)
  }

  scrollToBottom() {
    if (this.hasMessagesContainerTarget) {
      this.messagesContainerTarget.scrollTop = this.messagesContainerTarget.scrollHeight
    }
  }

  showConnectionStatus(message, status) {
    if (this.hasConnectionStatusTarget) {
      const statusElement = this.connectionStatusTarget
      const indicator = statusElement.querySelector('.w-2.h-2')
      
      statusElement.querySelector('span').textContent = message
      statusElement.style.display = 'block'
      
      // Update indicator color
      indicator.className = `w-2 h-2 rounded-full ${this.getStatusColor(status)}`
    }
  }

  hideConnectionStatus() {
    if (this.hasConnectionStatusTarget) {
      this.connectionStatusTarget.style.display = 'none'
    }
  }

  getStatusColor(status) {
    const colors = {
      'connecting': 'bg-yellow-400 animate-pulse',
      'connected': 'bg-green-400',
      'disconnected': 'bg-red-400 animate-pulse'
    }
    return colors[status] || 'bg-gray-400'
  }

  showKnowledgeExtractedNotification(entitiesCount, confidence) {
    if (entitiesCount > 0) {
      this.showNotification(
        `🧠 ${entitiesCount} neue Konzepte erfasst (${confidence}% Sicherheit)`,
        'success'
      )
    }
  }

  showNotification(message, type = 'info') {
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 glass-effect text-white px-4 py-3 rounded-lg shadow-lg z-50 transition-all duration-300 transform translate-x-full`
    notification.innerHTML = `
      <div class="flex items-center space-x-2">
        <div class="w-2 h-2 rounded-full ${type === 'success' ? 'bg-green-400' : 'bg-blue-400'}"></div>
        <span class="text-sm">${message}</span>
      </div>
    `
    
    document.body.appendChild(notification)
    
    // Animate in
    setTimeout(() => {
      notification.style.transform = 'translateX(0)'
    }, 10)
    
    // Animate out and remove
    setTimeout(() => {
      notification.style.transform = 'translateX(100%)'
      setTimeout(() => notification.remove(), 300)
    }, 4000)
  }

  showError(message) {
    this.showNotification(`⚠️ ${message}`, 'error')
  }

  // Method to send messages via Action Cable
  sendMessage(content, messageType = 'user') {
    if (this.subscription && content.trim()) {
      this.subscription.perform('send_message', {
        content: content,
        message_type: messageType
      })
      return true
    }
    return false
  }

  // Voice recording integration
  startVoiceRecording() {
    if (this.hasVoiceInterfaceTarget) {
      this.voiceInterfaceTarget.style.display = 'block'
    }
  }

  stopVoiceRecording() {
    if (this.hasVoiceInterfaceTarget) {
      this.voiceInterfaceTarget.style.display = 'none'
    }
  }

  // Handle audio file upload
  handleAudioUpload(event) {
    const file = event.target.files[0]
    if (file) {
      this.uploadAudioFile(file)
    }
  }

  async uploadAudioFile(audioFile) {
    const formData = new FormData()
    formData.append('audio', audioFile)
    formData.append('session_id', this.sessionIdValue)
    
    this.showNotification("🎙️ Audio wird transkribiert...", 'info')
    
    try {
      const response = await fetch('/audio/transcribe', {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })
      
      const data = await response.json()
      
      if (data.success) {
        this.showNotification(
          `✅ Audio transkribiert (${data.confidence * 100}% genau)`, 
          'success'
        )
      } else {
        this.showError(`Audio-Transkription fehlgeschlagen: ${data.error}`)
      }
    } catch (error) {
      console.error('Audio upload error:', error)
      this.showError('Audio-Upload fehlgeschlagen')
    }
  }

  showTypingIndicator() {
    // Implementation for typing indicator
  }

  hideTypingIndicator() {
    // Implementation for typing indicator
  }
}