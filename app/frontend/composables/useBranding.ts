import { ref, computed } from 'vue'

interface BrandingConfig {
  companyName: string
  companyLogo: string
  colors: Record<string, string>
  theme: Record<string, string>
  supportEmail: string
  supportPhone: string
  supportUrl: string
}

const brandingConfig = ref<BrandingConfig>({
  companyName: 'Leasys',
  companyLogo: '/assets/leasys_logo.png',
  colors: {
    primary: '#1e88e5',
    secondary: '#424242',
    accent: '#ff6f00',
    success: '#43a047',
    warning: '#fb8c00',
    error: '#e53935',
    background: '#fafafa',
  },
  theme: {
    fontFamily: 'Inter, sans-serif',
    borderRadius: '4px',
    boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
    transition: 'all 0.3s ease',
  },
  supportEmail: 'support@leasys.com',
  supportPhone: '+1-800-LEASYS',
  supportUrl: 'https://support.leasys.com',
})

export const useBranding = () => {
  const brandingColors = computed(() => brandingConfig.value.colors)
  const brandingTheme = computed(() => brandingConfig.value.theme)
  const companyName = computed(() => brandingConfig.value.companyName)
  const companyLogo = computed(() => brandingConfig.value.companyLogo)
  const supportInfo = computed(() => ({
    email: brandingConfig.value.supportEmail,
    phone: brandingConfig.value.supportPhone,
    url: brandingConfig.value.supportUrl,
  }))

  const setBranding = (config: Partial<BrandingConfig>) => {
    brandingConfig.value = {
      ...brandingConfig.value,
      ...config,
    }
  }

  return {
    brandingColors,
    brandingTheme,
    companyName,
    companyLogo,
    supportInfo,
    setBranding,
  }
}
