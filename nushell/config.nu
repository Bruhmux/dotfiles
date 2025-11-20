# config.nu
#
# Installed by:
# version = "0.108.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

# Remove welcome message
$env.config.show_banner = false
$env.EDITOR = 'nvim'


source scripts/carapace.nu
source scripts/starship.nu
source scripts/zoxide.nu
source scripts/yazi.nu
source scripts/tmux.nu


alias c = __zoxide_z
alias ci = __zoxide_zi

alias cl = clear
alias l = ls
alias lsa = ls -a
alias la = ls -a
alias lt = eza -T

alias wttr = curl wttr.in

def gac [msg: string] {
    git add .
    git commit -m $msg
}


