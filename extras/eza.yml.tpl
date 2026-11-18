# eza colors. Omarchy renders this template with the active theme's colors on
# every theme switch, and ~/.config/eza/theme.yml links to the result.
colourful: true

filekinds:
  normal: {foreground: "{{ foreground }}"}
  directory: {foreground: "{{ accent }}", is_bold: true}
  symlink: {foreground: "{{ cyan }}"}
  pipe: {foreground: "{{ muted }}"}
  block_device: {foreground: "{{ red }}"}
  char_device: {foreground: "{{ red }}"}
  socket: {foreground: "{{ muted }}"}
  special: {foreground: "{{ magenta }}"}
  executable: {foreground: "{{ green }}", is_bold: true}
  mount_point: {foreground: "{{ bright_cyan }}"}

perms:
  user_read: {foreground: "{{ foreground }}"}
  user_write: {foreground: "{{ yellow }}"}
  user_execute_file: {foreground: "{{ green }}"}
  user_execute_other: {foreground: "{{ green }}"}
  group_read: {foreground: "{{ light_foreground }}"}
  group_write: {foreground: "{{ yellow }}"}
  group_execute: {foreground: "{{ green }}"}
  other_read: {foreground: "{{ dark_foreground }}"}
  other_write: {foreground: "{{ yellow }}"}
  other_execute: {foreground: "{{ green }}"}
  special_user_file: {foreground: "{{ magenta }}"}
  special_other: {foreground: "{{ muted }}"}
  attribute: {foreground: "{{ dark_foreground }}"}

size:
  major: {foreground: "{{ dark_foreground }}"}
  minor: {foreground: "{{ cyan }}"}
  number_byte: {foreground: "{{ foreground }}"}
  number_kilo: {foreground: "{{ light_foreground }}"}
  number_mega: {foreground: "{{ blue }}"}
  number_giga: {foreground: "{{ magenta }}"}
  number_huge: {foreground: "{{ magenta }}"}
  unit_byte: {foreground: "{{ dark_foreground }}"}
  unit_kilo: {foreground: "{{ blue }}"}
  unit_mega: {foreground: "{{ magenta }}"}
  unit_giga: {foreground: "{{ magenta }}"}
  unit_huge: {foreground: "{{ cyan }}"}

users:
  user_you: {foreground: "{{ foreground }}"}
  user_root: {foreground: "{{ red }}"}
  user_other: {foreground: "{{ magenta }}"}
  group_yours: {foreground: "{{ light_foreground }}"}
  group_other: {foreground: "{{ muted }}"}
  group_root: {foreground: "{{ red }}"}

links:
  normal: {foreground: "{{ cyan }}"}
  multi_link_file: {foreground: "{{ bright_cyan }}"}

git:
  new: {foreground: "{{ green }}"}
  modified: {foreground: "{{ yellow }}"}
  deleted: {foreground: "{{ red }}"}
  renamed: {foreground: "{{ cyan }}"}
  typechange: {foreground: "{{ magenta }}"}
  ignored: {foreground: "{{ muted }}"}
  conflicted: {foreground: "{{ bright_red }}"}

git_repo:
  branch_main: {foreground: "{{ foreground }}"}
  branch_other: {foreground: "{{ magenta }}"}
  git_clean: {foreground: "{{ green }}"}
  git_dirty: {foreground: "{{ red }}"}

security_context:
  colon: {foreground: "{{ muted }}"}
  user: {foreground: "{{ light_foreground }}"}
  role: {foreground: "{{ magenta }}"}
  typ: {foreground: "{{ muted }}"}
  range: {foreground: "{{ magenta }}"}

file_type:
  image: {foreground: "{{ yellow }}"}
  video: {foreground: "{{ red }}"}
  music: {foreground: "{{ green }}"}
  lossless: {foreground: "{{ cyan }}"}
  crypto: {foreground: "{{ muted }}"}
  document: {foreground: "{{ foreground }}"}
  compressed: {foreground: "{{ magenta }}"}
  temp: {foreground: "{{ muted }}"}
  compiled: {foreground: "{{ bright_blue }}"}
  build: {foreground: "{{ muted }}"}
  source: {foreground: "{{ blue }}"}

punctuation: {foreground: "{{ muted }}"}
date: {foreground: "{{ blue }}"}
inode: {foreground: "{{ dark_foreground }}"}
blocks: {foreground: "{{ muted }}"}
header: {foreground: "{{ foreground }}", is_bold: true}
octal: {foreground: "{{ cyan }}"}
flags: {foreground: "{{ magenta }}"}

symlink_path: {foreground: "{{ cyan }}"}
control_char: {foreground: "{{ bright_cyan }}"}
broken_symlink: {foreground: "{{ red }}"}
broken_path_overlay: {foreground: "{{ muted }}"}
