/** Design tokens extracted from design.pen */
export const colors = {
  primary: '#0047b3',
  primaryDark: '#003080',
  primaryLight: '#E8F0FE',

  bg: '#F5F7FA',
  bgCard: '#FFFFFF',
  bgWhite: '#FFFFFF',

  border: '#E5E7EB',
  borderLight: '#F0F0F0',

  textPrimary: '#1A1A2E',
  textSecondary: '#6B7280',
  textMuted: '#9CA3AF',
  textWhite: '#FFFFFF',

  // Transit modes
  driveBlue: '#3B82F6',
  metroOrange: '#FF6319',
  busBlue: '#0078D4',
  tramGreen: '#00A651',
  railPurple: '#8B5CF6',
  ferryCyan: '#06B6D4',
  walkGray: '#9CA3AF',

  // Availability
  availHigh: '#10B981',
  availMedium: '#F59E0B',
  availLow: '#EF4444',
  availNeutral: '#B0BEC5',
} as const;

export const fonts = {
  heading: 'DMSans-Bold',
  body: 'DMSans-Regular',
  bodyMedium: 'DMSans-Medium',
  bodySemiBold: 'DMSans-SemiBold',
} as const;

export const radii = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  xxxl: 32,
} as const;
