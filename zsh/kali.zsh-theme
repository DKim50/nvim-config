# Kali Linux style prompt for oh-my-zsh: the two-line "twoline" prompt from
# Kali's own ~/.zshrc, in Kali's terminal colors (Kali-Dark).
#
#   ┌──(user㉿computer)-[~/.config/nvim]-[main ✗]
#   └─$
#
# Added on top of Kali's: the git branch, like oh-my-zsh's robbyrussell
# prompt (✗ = changes not committed yet). In a Python venv its name shows
# first: ┌──(venv)─(user㉿...
#
# Lives in the nvim-config repo (~/.config/nvim/zsh/). oh-my-zsh reads it
# through a link:
#   ~/.oh-my-zsh/custom/themes/kali.zsh-theme -> ~/.config/nvim/zsh/kali.zsh-theme
# Turn on with ZSH_THEME="kali" in ~/.zshrc. Switch back with
# ZSH_THEME="robbyrussell", then open a new tab.

() {
  local green='#5ebdab' blue='#367bf0' orange='#fea44c' red='#d41919'

  # Line 1: ┌──(venv)─(user㉿computer)-[folder]-[branch]
  # Line 2: └─$   ( # in red when you're root )
  # Long folder paths keep the first folder and the last 4: ~/…/a/b/c/d
  PROMPT="%F{$green}┌──\${VIRTUAL_ENV:+(\$(basename \$VIRTUAL_ENV))─}(%B%F{$blue}%n㉿%m%b%F{$green})-[%B%F{default}%(6~.%-1~/…/%4~.%5~)%b%F{$green}]\$(git_prompt_info)
%F{$green}└─%B%(#.%F{$red}#.%F{$blue}\$)%b%f "
  RPROMPT=''

  ZSH_THEME_GIT_PROMPT_PREFIX="%F{$green}-[%B%F{$orange}"
  ZSH_THEME_GIT_PROMPT_SUFFIX="%b%F{$green}]%f"
  ZSH_THEME_GIT_PROMPT_DIRTY=" %F{$red}✗"
  ZSH_THEME_GIT_PROMPT_CLEAN=""
}

# The venv name is already in the prompt, so don't let activate add another
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Kali puts a blank line before every prompt except the first, which spaces
# out each command and its output. After "clear" it starts at the top again.
autoload -Uz add-zsh-hook
_kali_blank_line() {
  [[ -n $_kali_prompt_shown ]] && print ""
  _kali_prompt_shown=1
}
_kali_after_clear() {
  [[ $1 == clear || $1 == "clear "* ]] && unset _kali_prompt_shown
}
add-zsh-hook precmd _kali_blank_line
add-zsh-hook preexec _kali_after_clear
