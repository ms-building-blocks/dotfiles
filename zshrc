# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

### Do we run interactively?
[[ $- != *i* ]] && return

### Do we profile ?

# Credit: https://kev.inburke.com/kevin/profiling-zsh-startup-time/

PROFILE_STARTUP=false
if [[ "$PROFILE_STARTUP" == true ]]; then
    zmodload zsh/zprof # Output load-time statistics
    # http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html
    PS4=$'%D{%M%S%.} %N:%i> '
    exec 3>&2 2>"${XDG_CACHE_HOME:-$HOME/tmp}/zsh_statup.$$"
    setopt xtrace prompt_subst
fi

# custom completion scripts
fpath=($HOME/dotfiles/completions $fpath)

# params block

# /params block
# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="robbyrussell"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Uncomment this to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how often before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want to disable command autocorrection
# DISABLE_CORRECTION="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Uncomment following line if you want to disable marking untracked files under
# VCS as dirty. This makes repository status check for large repositories much,
# much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment following line if you want to  shown in the command execution time stamp
# in the history command output. The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|
# yyyy-mm-dd
# HIST_STAMPS="mm/dd/yyyy"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(composer docker-compose kubectl) #shrink-path for fish like

source $ZSH/oh-my-zsh.sh

# User configuration

export PATH=$HOME/bin:/usr/local/bin:$PATH
export IBUS_ENABLE_SYNC_MODE=1 # JetBrains issues with IBus prior 1.5.11

# export MANPATH="/usr/local/man:$MANPATH"

# DETECT CHRUBY support

if [[ -d /usr/local/share/chruby/ ]]; then
	# Linux installation of chruby
	chruby_path=/usr/local/share/chruby/
elif [[ -d /usr/local/opt/chruby/share/chruby/ ]]; then
	# Homebrew installation of chruby
	chruby_path=/usr/local/opt/chruby/share/chruby/
fi

if [[ -d $chruby_path ]]; then
	source $chruby_path/chruby.sh
	source $chruby_path/auto.sh
fi

# # Preferred editor for local and remote sessions
 if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='nano'
 else
   export EDITOR='nano'
 fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

alias pps='ps -eo uname:20,pid,pcpu,pmem,sz,tty,stat,time,cmd'

if [[ -f /usr/bin/tmux ]]; then

if [[ -d /mnt/c/Windows/ ]]; then
# Holy shit, I am on windows linux subsystem

function onproject() {
  TMUXMODE=$2 tmuxinator ${1}_env
}

else

function onproject() {
  TMUXMODE=$2 gnome-terminal -x tmuxinator ${1}_env &
}

fi

function offproject() {
  tmux kill-session -t ${1} &
}

autoload -Uz onproject
autoload -Uz offproject

alias killproject='tmux kill-server'

fi

if [[ -f ~/dotfiles/ssh/ssh-ident ]]; then
# aliases
alias ssh='export LC_ALL=C;~/dotfiles/ssh/ssh-ident'
alias git='BINARY_SSH=git ~/dotfiles/ssh/ssh-ident'
fi

if [[ -f /usr/bin/direnv ]]; then
# direnv
eval "$(direnv hook zsh)"
fi

# Start built-in LAMP server in current directory
alias web='python -m SimpleHTTPServer 8000'
alias webcors='http-server -p 8000 --cors'

# remove locally all branches merged into develop
alias gitclean='git branch --merged develop | grep -v "\* develop" | xargs -n 1 git branch -d'


if [[ -f /usr/bin/docker ]]; then

#docker helpers

function dck() {

case "$1" in
    list)
        sudo docker ps -a
        ;;
    ui)
        docker start docker_ui || docker run -d -p 9999:9000 --name docker_ui --privileged -v /var/run/docker.sock:/var/run/docker.sock uifd/ui-for-docker
        ;;
    inspect)
        docker inspect $2 | jq $3
        ;;
    stopall)
        sudo docker stop $(sudo docker ps -a -q)
        ;;
    sh)
        sudo docker exec -it $(sudo docker ps -lq) ${2-/bin/sh} $3 $4 $5 $6 $7 $8 $9
        ;;

    bash)
        sudo docker exec -it $(sudo docker ps -lq) ${2-/bin/bash} $3 $4 $5 $6 $7 $8 $9
        ;;

    cleanimages)
        if [[ ! -f /usr/sbin/docker-gc ]]; then
        sudo docker rmi $(docker images | grep "^<none>"  | awk "{ print $3 }")
        else
        sudo EXCLUDE_FROM_GC={$EXCLUDE_FROM_GC-/etc/docker-gc-exclude} MINIMUM_IMAGES_TO_SAVE=1 FORCE_IMAGE_REMOVAL=1 docker-gc
        fi
        docker rmi $(docker images -f "dangling=true" -q)
        ;;
    cleancontainers)
        if [[ ! -f /usr/bin/docker ]]; then
        docker ps -a | grep 'weeks ago' | awk '{print $1}' | xargs --no-run-if-empty docker rm
        else
        sudo EXCLUDE_CONTAINERS_FROM_GC={$EXCLUDE_CONTAINERS_FROM_GC-/etc/docker-gc-exclude-containers} docker-gc
        fi

        ;;
    registry)
        docker start registry || docker run -d -p 5000:5000 --restart=always --name registry registry:2
        ;;
    *)
        echo "Usage: $0 {dck sh | bash | list |stopall |cleanimages |cleancontainers | ui | registry | inspect <container name> <jq filter>}"
        ;;
esac

}

autoload -Uz dck

fi


if type "gcloud" > /dev/null; then

source ${HOME}/dotfiles/completions/gcloud_completion.zsh


fi

if type "kubectl" > /dev/null; then
  # load support for kubernetes context switch
  export PATH=$PATH:${HOME}/dotfiles/docker

# heavy init
function onkubernetes() {
  source ${HOME}/dotfiles/docker/kube-ps1.sh
  source ${HOME}/dotfiles/docker/gcloud.zsh
  RPROMPT='$(kube_ps1)-%{$fg[yellow]%}($ZSH_GCLOUD_PROMPT_PROJECT)%{$reset_color%}'
}

fi


# ssh - add's github public ssh keys to authorized_keys of the current host
alias authorize_me='curl -L http://bit.ly/voronenko | bash -s'
alias mykey='xclip -selection c -i ~/.ssh/id_rsa.pub'

if [[ -f ~/dotfiles/gitflow/release_start.sh ]]; then

# gitflow
alias gitflow-init='git flow init -f -d'
alias gitflow-release-start='~/dotfiles/gitflow/release_start.sh'
alias gitflow-release-finish='~/dotfiles/gitflow/release_finish.sh'
alias gitflow-hotfix-start='~/dotfiles/gitflow/hotfix_start.sh'
alias gitflow-hotfix-finish='~/dotfiles/gitflow/hotfix_finish.sh'

fi

# sharing
alias sessionshare='screen -d -m -S shared'
alias sessionjoin='screen -x shared'
alias wanip='getent hosts `dig +short myip.opendns.com @resolver1.opendns.com`'

# source management
alias reset_rights_here='find -type f -exec chmod --changes 644 {} + -o -type d -exec chmod --changes 755 {} +'


# [ -f ~/.travis/travis.sh ] && source ~/.travis/travis.sh

if [[ -f ~/.nvm/nvm.sh ]]; then

source ~/.nvm/nvm.sh

# place this after nvm initialization!
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

fi

# Python development

if [[ -f /usr/local/bin/virtualenvwrapper.sh ]]; then

mkdir -p ~/.virtualenvs
export WORKON_HOME=$HOME/.virtualenvs
source /usr/local/bin/virtualenvwrapper.sh

fi

if [[ -d ~/.virtualenvs/project_notes ]]; then

alias znotes='workon project_notes && cd ${ZNOTES_PATH-~/z_personal_notes} && jupyter lab'

fi


# Java development

if [[ -d /opt/gradle ]]; then

export PATH=$PATH:/opt/gradle/gradle-3.3/bin

fi

# /Java development


# Autoload ssh agent

SSH_ENV="$HOME/.ssh/environment"

function start_agent {
#    echo "Initialising new SSH agent..."
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add > /dev/null;
}

# Source SSH settings, if applicable

if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    #ps ${SSH_AGENT_PID} doesn't work under cywgin
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    start_agent;
fi


if [[ -n $SSH_CONNECTION ]]; then
echo " .... remote session `echo $USER`@`hostname` .... "
#PROMPT="%{$fg_bold[yellow]%}⇕ ${ret_status} %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)"
PROMPT=$'%{$fg[yellow]%}┌%{$fg_bold[yellow]%}[⇕]%{$reset_color%}$fg[yellow]%}[%{$fg[cyan]%}%c%{$reset_color%}%{$fg[yellow]%}]> %{$(git_prompt_info)%}%(?,,%{$fg[yellow]%}[%{$fg_bold[white]%}%?%{$reset_color%}%{$fg[yellow]%}])
%{$fg[yellow]%}└──${ret_status}%{$reset_color%}'
PS2=$' %{$fg[green]%}|>%{$reset_color%} '

else
PROMPT=$'%{$fg[yellow]%}┌[%{$fg[cyan]%}%c%{$reset_color%}%{$fg[yellow]%}]> %{$(git_prompt_info)%}%(?,,%{$fg[yellow]%}[%{$fg_bold[white]%}%?%{$reset_color%}%{$fg[yellow]%}])
%{$fg[yellow]%}└──${ret_status}%{$reset_color%}'
PS2=$' %{$fg[green]%}|>%{$reset_color%} '

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[yellow]%}[%{$fg_bold[white]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}%{$fg[yellow]%}] "
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[yellow]%}⚡%{$reset_color%}"
fi



# Load cd helper
if [[ -f ~/dotfiles/helpers/z.sh ]]; then source ~/dotfiles/helpers/z.sh; fi

# Windows syntethic sugar

alias 'startdot'='xdg-open .'

# Anything locally specific?
if [[ -f ${HOME}/.zshrc.local ]]; then source ${HOME}/.zshrc.local; fi


# Time to sleep
alias 'nah'='echo "shutdown (ctrl-c to abort)?" && read && sudo shutdown 0'



if [[ "$PROFILE_STARTUP" == true ]]; then
    zprof > ~/dotfiles/startup.log
    unsetopt xtrace
    exec 2>&3 3>&-
fi

