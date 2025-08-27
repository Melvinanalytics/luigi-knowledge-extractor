import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    sessionId: String 
  }
  
  connect() {
    this.isListening = false
    this.isRecording = false
    this.mediaRecorder = null
    this.audioChunks = []
    this.setupSpeechRecognition()
  }

  disconnect() {
    this.cleanup()
  }

  toggle() {
    if (this.isListening || this.isRecording) {
      this.stop()
    } else {
      this.start()
    }
  }

  start() {
    // Check for microphone support
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.showError('Mikrofon wird von diesem Browser nicht unterstützt')
      return
    }

    // Try browser speech recognition first (for real-time feedback)
    if (this.recognition && !this.isListening) {
      this.startSpeechRecognition()
    } else {
      // Fallback to audio recording for server processing
      this.startAudioRecording()
    }
  }

  stop() {
    if (this.isListening) {
      this.stopSpeechRecognition()
    }
    if (this.isRecording) {
      this.stopAudioRecording()
    }
  }

  // Speech Recognition (Browser-based)
  setupSpeechRecognition() {
    if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
      const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition
      this.recognition = new SpeechRecognition()
      
      this.recognition.continuous = false
      this.recognition.interimResults = true
      this.recognition.lang = 'de-DE'
      this.recognition.maxAlternatives = 1

      this.recognition.onstart = () => this.handleRecognitionStart()
      this.recognition.onend = () => this.handleRecognitionEnd()
      this.recognition.onresult = (event) => this.handleRecognitionResult(event)
      this.recognition.onerror = (event) => this.handleRecognitionError(event)
    }
  }

  startSpeechRecognition() {
    if (!this.recognition) {
      this.startAudioRecording()
      return
    }

    try {
      this.isListening = true
      this.updateUI('listening')
      this.recognition.start()
    } catch (error) {
      console.error('Speech recognition start error:', error)
      this.startAudioRecording()
    }
  }

  stopSpeechRecognition() {
    if (this.recognition && this.isListening) {
      this.recognition.stop()
    }
  }

  handleRecognitionStart() {
    console.log('Speech recognition started')
    this.showSessionController()?.showNotification('🎙️ Zuhören...', 'info')
  }

  handleRecognitionEnd() {
    this.isListening = false
    this.updateUI('idle')
    console.log('Speech recognition ended')
  }

  handleRecognitionResult(event) {
    let finalTranscript = ''
    let interimTranscript = ''

    for (let i = event.resultIndex; i < event.results.length; i++) {
      const transcript = event.results[i][0].transcript
      if (event.results[i].isFinal) {
        finalTranscript += transcript
      } else {
        interimTranscript += transcript
      }
    }

    if (finalTranscript) {
      this.insertTranscriptIntoTextarea(finalTranscript)
      this.showSessionController()?.showNotification(
        `✅ "${finalTranscript.slice(0, 30)}..." erkannt`, 
        'success'
      )
    }
  }

  handleRecognitionError(event) {
    console.error('Speech recognition error:', event.error)
    this.isListening = false
    this.updateUI('idle')
    
    if (event.error !== 'aborted') {
      this.showError(`Spracherkennung fehlgeschlagen: ${event.error}`)
    }
  }

  // Audio Recording (for server processing)
  async startAudioRecording() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          channelCount: 1,
          sampleRate: 16000, // Optimized for Whisper
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true
        }
      })

      this.audioChunks = []
      this.mediaRecorder = new MediaRecorder(stream, {
        mimeType: 'audio/webm;codecs=opus'
      })

      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          this.audioChunks.push(event.data)
        }
      }

      this.mediaRecorder.onstop = () => this.handleRecordingComplete()

      this.mediaRecorder.start()
      this.isRecording = true
      this.updateUI('recording')
      this.startRecordingTimer()

      this.showSessionController()?.showNotification('🔴 Aufnahme läuft...', 'info')

    } catch (error) {
      console.error('Audio recording start error:', error)
      this.showError('Mikrofonzugriff wurde verweigert')
    }
  }

  stopAudioRecording() {
    if (this.mediaRecorder && this.isRecording) {
      this.mediaRecorder.stop()
      this.mediaRecorder.stream.getTracks().forEach(track => track.stop())
      this.isRecording = false
      this.stopRecordingTimer()
      this.updateUI('processing')
    }
  }

  handleRecordingComplete() {
    if (this.audioChunks.length === 0) {
      this.showError('Keine Audiodaten aufgenommen')
      this.updateUI('idle')
      return
    }

    const audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' })
    this.uploadAudioForTranscription(audioBlob)
  }

  async uploadAudioForTranscription(audioBlob) {
    const formData = new FormData()
    formData.append('audio', audioBlob, 'recording.webm')
    formData.append('session_id', this.sessionIdValue)

    try {
      const response = await fetch('/audio/transcribe', {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      const data = await response.json()

      if (data.success && data.transcription) {
        this.insertTranscriptIntoTextarea(data.transcription)
        this.showSessionController()?.showNotification(
          `✅ Audio transkribiert (${Math.round(data.confidence * 100)}% genau)`, 
          'success'
        )
      } else {
        this.showError(`Transkription fehlgeschlagen: ${data.error || 'Unbekannter Fehler'}`)
      }
    } catch (error) {
      console.error('Audio transcription error:', error)
      this.showError('Audio-Upload fehlgeschlagen')
    } finally {
      this.updateUI('idle')
    }
  }

  insertTranscriptIntoTextarea(transcript) {
    const textareaElement = document.querySelector('[data-message-form-target="textarea"]')
    if (textareaElement) {
      const currentValue = textareaElement.value
      const newValue = currentValue + (currentValue ? ' ' : '') + transcript
      textareaElement.value = newValue
      textareaElement.focus()
      
      // Trigger input event for character counter update
      textareaElement.dispatchEvent(new Event('input'))
    }
  }

  updateUI(state) {
    const states = {
      idle: {
        classes: 'bg-white/20 hover:bg-white/30',
        title: 'Sprachaufnahme starten'
      },
      listening: {
        classes: 'bg-blue-500 animate-pulse',
        title: 'Zuhören... (Browser-Spracherkennung)'
      },
      recording: {
        classes: 'bg-red-500 animate-pulse',
        title: 'Aufnahme läuft... (Klicken zum Stoppen)'
      },
      processing: {
        classes: 'bg-yellow-500 animate-pulse',
        title: 'Verarbeitung...'
      }
    }

    const config = states[state] || states.idle
    this.element.className = `p-3 rounded-xl transition-colors text-white flex-shrink-0 ${config.classes}`
    this.element.title = config.title
  }

  startRecordingTimer() {
    this.recordingStartTime = Date.now()
    this.recordingTimer = setInterval(() => {
      const elapsed = Math.floor((Date.now() - this.recordingStartTime) / 1000)
      const minutes = Math.floor(elapsed / 60)
      const seconds = elapsed % 60
      
      // Update timer display if available
      const timerElement = document.querySelector('[data-voice-recorder-target="duration"]')
      if (timerElement) {
        timerElement.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`
      }

      // Auto-stop after 5 minutes to prevent huge files
      if (elapsed >= 300) {
        this.stop()
      }
    }, 1000)
  }

  stopRecordingTimer() {
    if (this.recordingTimer) {
      clearInterval(this.recordingTimer)
      this.recordingTimer = null
    }
  }

  showSessionController() {
    const sessionElement = document.querySelector('[data-controller*="luigi-session"]')
    if (sessionElement) {
      return this.application.getControllerForElementAndIdentifier(
        sessionElement,
        'luigi-session'
      )
    }
    return null
  }

  showError(message) {
    const sessionController = this.showSessionController()
    if (sessionController) {
      sessionController.showError(message)
    } else {
      alert(message) // Fallback
    }
  }

  cleanup() {
    this.stopRecordingTimer()
    
    if (this.mediaRecorder && this.isRecording) {
      this.mediaRecorder.stop()
      this.mediaRecorder.stream.getTracks().forEach(track => track.stop())
    }

    if (this.recognition && this.isListening) {
      this.recognition.stop()
    }
  }
}