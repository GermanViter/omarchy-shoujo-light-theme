return {
  {
    "omacom/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = "#e5e9f0",
        dark_bg = "#dce1e9",
        darker_bg = "#d2d7e0",
        lighter_bg = "#eef1f5",

        fg = "#2e3440",
        dark_fg = "#7a7e85",
        light_fg = "#3b4250",
        bright_fg = "#1f242d",
        muted = "#9fa3a9",

        red = "#a3434f",
        yellow = "#8a6a2a",
        orange = "#a35a3c",
        green = "#4f7350",
        cyan = "#3f7580",
        blue = "#4a6491",
        magenta = "#85587d",
        brown = "#6b5550",

        bright_red = "#b8575f",
        bright_yellow = "#9e7c38",
        bright_green = "#5f8560",
        bright_cyan = "#4f8794",
        bright_blue = "#5b76a3",
        bright_magenta = "#986b90",

        accent = "#4c5a73",
        cursor = "#1f242d",
        foreground = "#2e3440",
        background = "#e5e9f0",
        selection = "#c9ced8",
        selection_foreground = "#1f242d",
        selection_background = "#c9ced8",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
