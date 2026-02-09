/** @type {import('tailwindcss').Config} */
import defaultTheme from 'tailwindcss/defaultTheme';

export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        brand: {
          DEFAULT: '#1e40af', // blue-800 (Corporate Blue)
          dark: '#1e3a8a',    // blue-900 (Deep Navy for hover/accents)
          light: '#eff6ff',   // blue-50 (Backgrounds)
        },
        accent: {
          DEFAULT: '#0891b2', // cyan-600
        }
      },
    },
  },
  plugins: [],
}
