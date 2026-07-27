<template>
  <div class="request-form" :style="{ backgroundColor: brandingColors.background }">
    <div class="form-container">
      <div class="form-header">
        <h1>Request a Service</h1>
        <p>Submit requests for access, information, or account changes</p>
      </div>

      <form @submit.prevent="submitForm" class="ticket-form">
        <!-- Request Type -->
        <div class="form-group">
          <label for="requestType" class="required">Type of Request</label>
          <select
            id="requestType"
            v-model="form.requestType"
            class="form-control"
            @change="form.specificData = {}"
            required
          >
            <option value="">-- Select request type --</option>
            <option value="password_reset">Password Reset</option>
            <option value="starter_form">Starter Form (New Employee)</option>
            <option value="leaver_form">Leaver Form (Employee Departure)</option>
            <option value="transfer_form">Transfer Form (Role Change)</option>
            <option value="information_request">Information Request</option>
          </select>
        </div>

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

        <!-- PASSWORD RESET SECTION -->
        <template v-if="form.requestType === 'password_reset'">
          <div class="section-header">Password Reset Details</div>
          <div class="form-group">
            <label for="system" class="required">Which system?</label>
            <select
              id="system"
              v-model="form.specificData.system"
              class="form-control"
              required
            >
              <option value="">-- Select system --</option>
              <option value="email">Email</option>
              <option value="vpn">VPN</option>
              <option value="erp">ERP System</option>
              <option value="crm">CRM System</option>
              <option value="other">Other</option>
            </select>
          </div>
          <div class="form-group">
            <label for="login" class="required">Your login/username</label>
            <input
              id="login"
              v-model="form.specificData.login"
              type="text"
              class="form-control"
              placeholder="Enter your username or login"
              required
            />
          </div>
        </template>

        <!-- STARTER FORM SECTION -->
        <template v-if="form.requestType === 'starter_form'">
          <div class="section-header">New Employee Information</div>
          <div class="form-group">
            <label for="firstName" class="required">First Name</label>
            <input
              id="firstName"
              v-model="form.specificData.firstName"
              type="text"
              class="form-control"
              placeholder="First name"
              required
            />
          </div>
          <div class="form-group">
            <label for="lastName" class="required">Last Name</label>
            <input
              id="lastName"
              v-model="form.specificData.lastName"
              type="text"
              class="form-control"
              placeholder="Last name"
              required
            />
          </div>
          <div class="form-group">
            <label for="approverStarterEmail" class="required">Approver Email Address</label>
            <input
              id="approverStarterEmail"
              v-model="form.specificData.approverEmail"
              type="email"
              class="form-control"
              placeholder="manager.email@company.com"
              required
            />
          </div>
          <div class="form-group">
            <label for="accessNeeds" class="required">What access does the person need?</label>
            <textarea
              id="accessNeeds"
              v-model="form.specificData.accessNeeds"
              class="form-control"
              placeholder="List all systems and access permissions needed (e.g., Email, VPN, ERP, CRM, File Shares, etc.)"
              rows="4"
              required
            />
          </div>
        </template>

        <!-- LEAVER FORM SECTION -->
        <template v-if="form.requestType === 'leaver_form'">
          <div class="section-header">Employee Departure Information</div>
          <div class="form-group">
            <label for="employeeId" class="required">Employee ID or Email</label>
            <input
              id="employeeId"
              v-model="form.specificData.employeeId"
              type="text"
              class="form-control"
              placeholder="ID or email address"
              required
            />
          </div>
          <div class="form-group">
            <label for="departureType" class="required">Departure Type</label>
            <select
              id="departureType"
              v-model="form.specificData.departureType"
              class="form-control"
              required
            >
              <option value="">-- Select type --</option>
              <option value="permanent">Permanent Delete All Access</option>
              <option value="temporary">Temporary Suspend Access</option>
            </select>
          </div>
        </template>

        <!-- TRANSFER FORM SECTION -->
        <template v-if="form.requestType === 'transfer_form'">
          <div class="section-header">Employee Transfer Information</div>
          <div class="form-group">
            <label for="transferEmployeeId" class="required">Employee ID or Email</label>
            <input
              id="transferEmployeeId"
              v-model="form.specificData.employeeId"
              type="text"
              class="form-control"
              placeholder="ID or email address"
              required
            />
          </div>
          <div class="form-group">
            <label for="changeDescription" class="required">What change needs to be done?</label>
            <textarea
              id="changeDescription"
              v-model="form.specificData.changeDescription"
              class="form-control"
              placeholder="Describe the changes (e.g., New department, new role, new access needs, access to remove, etc.)"
              rows="4"
              required
            />
          </div>
        </template>

        <!-- INFORMATION REQUEST SECTION -->
        <template v-if="form.requestType === 'information_request'">
          <div class="section-header">Information Request Details</div>
          <div class="form-group">
            <label for="informationRequested" class="required">What information is requested?</label>
            <textarea
              id="informationRequested"
              v-model="form.specificData.informationRequested"
              class="form-control"
              placeholder="Describe the information you need (e.g., project status, documentation, reports, etc.)"
              rows="5"
              required
            />
          </div>
        </template>

        <!-- Form Actions -->
        <div class="form-actions">
          <button
            type="submit"
            class="btn btn-primary"
            :disabled="isSubmitting"
            :style="{ backgroundColor: brandingColors.primary }"
          >
            <span v-if="!isSubmitting">Submit Service Request</span>
            <span v-else>Submitting...</span>
          </button>
          <button type="reset" class="btn btn-secondary">
            Clear Form
          </button>
        </div>
      </form>

      <!-- Success Message -->
      <div v-if="submitSuccess" class="alert alert-success">
        <strong>Success!</strong> Your service request has been submitted. We'll contact you shortly.
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
  name: 'ServiceRequestForm',
  setup() {
    const { brandingColors } = useBranding()

    return {
      brandingColors,
      form: {
        requestType: '',
        userEmail: '',
        specificData: {},
      },
      isSubmitting: false,
      submitSuccess: false,
      submitError: null,
    }
  },
  methods: {
    async submitForm() {
      this.isSubmitting = true
      this.submitError = null
      this.submitSuccess = false

      try {
        const response = await fetch('/api/guest/tickets/service-request', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            requestType: this.form.requestType,
            userEmail: this.form.userEmail,
            specificData: this.form.specificData,
          }),
        })

        if (!response.ok) {
          throw new Error('Failed to submit service request')
        }

        this.submitSuccess = true
        this.form = {
          requestType: '',
          userEmail: '',
          specificData: {},
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
.request-form {
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

.section-header {
  font-size: 16px;
  font-weight: 600;
  color: #1e88e5;
  margin-top: 28px;
  margin-bottom: 16px;
  padding-bottom: 12px;
  border-bottom: 2px solid #e3f2fd;
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
