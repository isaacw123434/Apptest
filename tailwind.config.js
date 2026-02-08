/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: '#0f766e', // teal-700
          dark: '#0d9488',    // teal-600
          light: '#ccfbf1',   // teal-100 (backgrounds)
        },
        accent: {
          DEFAULT: '#0891b2', // cyan-600
        }
      },
    },
  },
  plugins: [],
}
