// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
module.exports = {
  content: ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      animation: {
        "fade-in": "0.2s ease-out 0s normal forwards 1 fade-in-keys",
        "fade-in-scale": "0.2s ease-in 0s normal forwards 1 fade-in-scale-keys",
        "fade-out": "0.2s ease-out 0s normal forwards 1 fade-out-keys",
        "fade-out-scale":
          "0.2s ease-out 0s normal forwards 1 fade-out-scale-keys",
        "slide-down": "0.2s ease-out normal forwards 1 slide-down-keys",
        "slide-up": "0.2s ease-in normal forwards 1 slide-up-keys",
      },
      keyframes: {
        "fade-in-keys": {
          "0%": { opacity: 0 },
          "100%": { opacity: 1 },
        },
        "fade-in-scale-keys": {
          "0%": { transform: "scale(0.75)", opacity: 0 },
          "100%": { transform: "scale(1)", opacity: 1 },
        },
        "fade-out-keys": {
          "0%": { opacity: 1 },
          "100%": { opacity: 0 },
        },
        "fade-out-scale-keys": {
          "0%": { transform: "scale(1)", opacity: 1 },
          "100%": { transform: "scale(0.75)", opacity: 0 },
        },
        "slide-down-keys": {
          "0%": { transform: "scaleY(0) translateY(-100%)", opacity: 0 },
          "100%": { transform: "scaleY(1) translateY(0)", opacity: 1 },
        },
        "slide-up-keys": {
          "0%": { transform: "scaleY(1) translateY(0)", opacity: 1 },
          "100%": { transform: "scaleY(0) translateY(-100%)", opacity: 0 },
        },
      },
    },
  },
  plugins: [require("@tailwindcss/forms")],
};
