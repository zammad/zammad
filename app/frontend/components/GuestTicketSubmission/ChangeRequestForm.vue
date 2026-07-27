<template>
  <div class="change-form" :style="{ backgroundColor: brandingColors.background }">
    <div class="form-container">
      <div class="form-header">
        <h1>Request a Change</h1>
        <p>Submit a formal change request for systems or processes</p>
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
        </div>

        <!-- Approver Email -->
        <div class="form-group">
          <label for="approverEmail" class="required">Approver Director Email</label>
          <input
            id="approverEmail"
            v-model="form.approverEmail"
            type="email"
            class="form-control"
            placeholder="director.email@company.com"
            required
          />
        </div>

        <!-- Urgency -->
        <div class="form-group">
          <label for="urgency" class="required">Urgency Level</label>
          <select
            id="urgency"
            v-model="form.urgency"
            class="form-control"
            required
          >
            <option value="">-- Select urgency --</option>
            <option value="1">1 - Low (Planned)</option>
            <option value="2">2 - Medium (Scheduled)</option>
            <option value="3">3 - High (ASAP)</option>
          </select>
        </div>

        <!-- Change Size -->
        <div class="form-group">
          <label for="changeSize" class="required">Size of Change</label>
          <select
            id="changeSize"
            v-model="form.changeSize"
            class="form-control"
            required
          >
            <option value="">-- Select size --</option>
            <option value="s">S - Small (< 2 hours)</option>
            <option value="m">M - Medium (2-4 hours)</option>
            <option value="l">L - Large (4-8 hours)</option>
            <option value="xl">XL - Very Large (8-16 hours)</option>
            <option value="xxl">XXL - Massive (> 16 hours)</option>
          </select>
        </div>

        <!-- Description -->
        <div class="form-group">
          <label for="description" class="required">One Line Description</label>
          <input
            id="description"
            v-model="form.description"
            type="text"
            class="form-control"
            placeholder="Brief description of the change"
            maxlength="100"
            required
          />
          <small>{{ form.description.length }}/100 characters</small>
        </div>

        <!-- Current State -->
        <div class="form-group">
          <label for="currentState" class="required">What is happening currently</label>
          <textarea
            id="currentState"
            v-model="form.currentState"
            class="form-control"
            placeholder="Describe the current state of the system/process"
            rows="4"
            maxlength="2000"
            required
          />
          <small>{{ form.currentState.length }}/2000 characters</small>
        </div>

        <!-- Desired State -->
        <div class="form-group">
          <label for="desiredState" class="required">What should happen</label>
          <textarea
            id="desiredState"
            v-model="form.desiredState"
            class="form-control"
            placeholder="Describe the desired end state after the change"
            rows="4"
            maxlength="2000"
            required
          />
          <small>{{ form.desiredState.length }}/2000 characters</small>
        </div>

        <!-- Testing -->
        <div class="form-group">
          <label for="testing" class="required">Who will test the solution</label>
          <input
            id="testing"
            v-model="form.testing"
            type="text"
            class="form-control"
            placeholder="Name or department responsible for testing"
            required
          />
        </div>

        <!-- File Upload -->
        <div class="form-group">
          <label for="attachment">Attach Documentation or Images</label>
          <div class="file-upload">
            <input
              id="attachment"
              type="file"
              class="file-input"
              @change="handleFileUpload"
              accept="image/*,.pdf,.doc,.docx,.xlsx"
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
            <span v-if="!isSubmitting">Submit Change Request</span>
            <span v-else>Submitting...</span>
          </button>
          <button type="reset" class="btn btn-secondary">
            Clear Form
          </button>
        </div>
      </form>

      <!-- Success Message -->
      <div v-if="submitSuccess" class="alert alert-success">
        <strong>Success!</strong> Your change request has been submitted for approval.
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
  name: 'ChangeRequestForm',
  setup() {
    const { brandingColors } = useBranding()

    return {
      brandingColors,
      form: {
        userEmail: '',
        approverEmail: '',
        urgency: '',
        changeSize: '',
        description: '',
        currentState: '',
        desiredState: '',
        testing: '',
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
        formData.append('approverEmail', this.form.approverEmail)
        formData.append('urgency', this.form.urgency)
        formData.append('changeSize', this.form.changeSize)
        formData.append('description', this.form.description)
        formData.append('currentState', this.form.currentState)
        formData.append('desiredState', this.form.desiredState)
        formData.append('testing', this.form.testing)
        if (this.form.attachment) {
          formData.append('attachment', this.form.attachment)
        }

        const response = await fetch('/api/guest/tickets/change-request', {
          method: 'POST',
          body: formData,
        })

        if (!response.ok) {
          throw new Error('Failed to submit change request')
        }

        this.submitSuccess = true
        this.form = {
          userEmail: '',
          approverEmail: '',
          urgency: '',
          changeSize: '',
          description: '',
          currentState: '',
          desiredState: '',
          testing: '',
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
.change-form {
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
  min-height: 100px;
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
