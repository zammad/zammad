<template>
  <div class="incident-form" :style="{ backgroundColor: brandingColors.background }">
    <div class="form-container">
      <div class="form-header">
        <h1>Report an Incident</h1>
        <p>Let us know about any service disruptions or issues you're experiencing</p>
      </div>

      <form @submit.prevent="submitForm" class="ticket-form">
        <!-- User Email -->
        <div class="form-group">
          <label for="userEmail" class="required">Your Email Address</label>
          <input
            id="userEmail"
            v-model="form.userEmail"
            type="email"
            class="form-control"
            placeholder="your.email@company.com"
            required
          />
          <small>We'll send ticket updates to this email address</small>
        </div>

        <!-- Service Dropdown -->
        <div class="form-group">
          <label for="service" class="required">Affected Service</label>
          <select
            id="service"
            v-model="form.service"
            class="form-control"
            required
          >
            <option value="">-- Select a service --</option>
            <option value="applications">Applications</option>
            <option value="hardware">Hardware</option>
            <option value="other">Other</option>
          </select>
        </div>

        <!-- Priority Dropdown -->
        <div class="form-group">
          <label for="priority" class="required">Priority Level</label>
          <select
            id="priority"
            v-model="form.priority"
            class="form-control"
            required
          >
            <option value="">-- Select priority --</option>
            <option value="critical">1. Service doesn't work for everyone</option>
            <option value="high">2. Part of the service doesn't work</option>
            <option value="normal">3. Something doesn't work for me only</option>
          </select>
        </div>

        <!-- Summary -->
        <div class="form-group">
          <label for="summary" class="required">Issue Summary (one line)</label>
          <input
            id="summary"
            v-model="form.summary"
            type="text"
            class="form-control"
            placeholder="Brief description of the issue"
            maxlength="100"
            required
          />
          <small>{{ form.summary.length }}/100 characters</small>
        </div>

        <!-- Description -->
        <div class="form-group">
          <label for="description" class="required">Detailed Description</label>
          <textarea
            id="description"
            v-model="form.description"
            class="form-control"
            placeholder="Please provide detailed information about the issue, what you were doing when it happened, and any error messages you saw"
            rows="6"
            maxlength="2000"
            required
          />
          <small>{{ form.description.length }}/2000 characters</small>
        </div>

        <!-- File Upload -->
        <div class="form-group">
          <label for="attachment">Attach Screenshot or File</label>
          <div class="file-upload">
            <input
              id="attachment"
              type="file"
              class="file-input"
              @change="handleFileUpload"
              accept="image/*,.pdf,.doc,.docx"
            />
            <span v-if="form.attachment" class="file-name">
              ✓ {{ form.attachment.name }}
            </span>
            <span v-else class="file-hint">PDF, images, or documents up to 10MB</span>
          </div>
        </div>

        <!-- Form Actions -->
        <div class="form-actions">
          <button
            type="submit"
            class="btn btn-primary"
            :disabled="isSubmitting"
            :style="{ backgroundColor: brandingColors.primary }"
          >
            <span v-if="!isSubmitting">Submit Incident Report</span>
            <span v-else>Submitting...</span>
          </button>
          <button type="reset" class="btn btn-secondary">
            Clear Form
          </button>
        </div>
      </form>

      <!-- Success Message -->
      <div v-if="submitSuccess" class="alert alert-success">
        <strong>Success!</strong> Your incident has been submitted. Check your email for ticket reference number.
      </div>

      <!-- Error Message -->
      <div v-if="submitError" class="alert alert-error">
        <strong>Error:</strong> {{ submitError }}
      </div>
    </div>
  </div>
</template>

<script>
import { defineComponent } from 'vue'
import { useBranding } from '@/composables/useBranding'

export default defineComponent({
  name: 'IncidentForm',
  setup() {
    const { brandingColors } = useBranding()

    return {
      brandingColors,
      form: {
        userEmail: '',
        service: '',
        priority: '',
        summary: '',
        description: '',
        attachment: null,
      },
      isSubmitting: false,
      submitSuccess: false,
      submitError: null,
    }
  },
  methods: {
    handleFileUpload(event) {
      const file = event.target.files[0]
      if (file && file.size <= 10 * 1024 * 1024) {
        this.form.attachment = file
      } else {
        this.submitError = 'File size must be less than 10MB'
      }
    },
    async submitForm() {
      this.isSubmitting = true
      this.submitError = null
      this.submitSuccess = false

      try {
        const formData = new FormData()
        formData.append('userEmail', this.form.userEmail)
        formData.append('service', this.form.service)
        formData.append('priority', this.form.priority)
        formData.append('summary', this.form.summary)
        formData.append('description', this.form.description)
        if (this.form.attachment) {
          formData.append('attachment', this.form.attachment)
        }

        const response = await fetch('/api/guest/tickets/incident', {
          method: 'POST',
          body: formData,
        })

        if (!response.ok) {
          throw new Error('Failed to submit incident')
        }

        this.submitSuccess = true
        this.$refs.form?.reset()
        this.form = {
          userEmail: '',
          service: '',
          priority: '',
          summary: '',
          description: '',
          attachment: null,
        }
      } catch (error) {
        this.submitError = error.message
      } finally {
        this.isSubmitting = false
      }
    },
  },
})
</script>

<style scoped>
.incident-form {
  min-height: 100vh;
  padding: 40px 20px;
}

.form-container {
  max-width: 600px;
  margin: 0 auto;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  padding: 40px;
}

.form-header {
  margin-bottom: 30px;
  text-align: center;
}

.form-header h1 {
  font-size: 28px;
  font-weight: 600;
  margin-bottom: 10px;
}

.form-header p {
  color: #666;
  font-size: 16px;
}

.form-group {
  margin-bottom: 24px;
}

label {
  display: block;
  font-weight: 500;
  margin-bottom: 8px;
  font-size: 14px;
}

label.required::after {
  content: ' *';
  color: #e53935;
}

.form-control {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  font-family: inherit;
  transition: border-color 0.3s ease;
}

.form-control:focus {
  outline: none;
  border-color: #1e88e5;
  box-shadow: 0 0 0 3px rgba(30, 136, 229, 0.1);
}

textarea.form-control {
  resize: vertical;
  min-height: 120px;
}

small {
  display: block;
  margin-top: 4px;
  color: #999;
  font-size: 12px;
}

.file-upload {
  position: relative;
  border: 2px dashed #ddd;
  border-radius: 4px;
  padding: 20px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
}

.file-upload:hover {
  border-color: #1e88e5;
  background-color: rgba(30, 136, 229, 0.05);
}

.file-input {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  opacity: 0;
  cursor: pointer;
}

.file-name {
  color: #43a047;
  font-weight: 500;
}

.file-hint {
  color: #999;
}

.form-actions {
  display: flex;
  gap: 12px;
  margin-top: 30px;
}

.btn {
  flex: 1;
  padding: 12px 20px;
  border: none;
  border-radius: 4px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-primary {
  color: white;
}

.btn-primary:hover:not(:disabled) {
  opacity: 0.9;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(30, 136, 229, 0.3);
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-secondary {
  background-color: #f5f5f5;
  color: #333;
  border: 1px solid #ddd;
}

.btn-secondary:hover {
  background-color: #efefef;
}

.alert {
  padding: 16px;
  border-radius: 4px;
  margin-top: 20px;
  font-size: 14px;
}

.alert-success {
  background-color: #e8f5e9;
  color: #2e7d32;
  border: 1px solid #c8e6c9;
}

.alert-error {
  background-color: #ffebee;
  color: #c62828;
  border: 1px solid #ffcdd2;
}
</style>
