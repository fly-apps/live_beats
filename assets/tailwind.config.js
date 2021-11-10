const colors = require('tailwindcss/colors')

module.exports = {
  darkMode: 'media',
  mode: 'jit',
  purge: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex'
  ],
  theme: {
    colors: colors
  },
  variants: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms')
  ],
}