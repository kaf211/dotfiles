fullname=`hostname -f 2>/dev/null || hostname`

# What kind of machine is this?
machine_type=':home:python'
case `uname` in
	Darwin) machine_type="$machine_type:mac";;
esac

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh
ZSH_THEME="kylemarsh"
ZSH_PROMPT_GLYPH="%%" #this is just for my theme
CASE_SENSITIVE="false"
DISABLE_AUTO_UPDATE="true" #oh-my-zsh updates
# DISABLE_AUTO_TITLE="true"
# DISABLE_CORRECTION="true"

base_plugins=(git history screen virtualenv)
python_plugins=(pip virtualenvwrapper)
mac_plugins=(battery brew terminalapp)

plugins=($base_plugins)
if [[ $machine_type =~ ':mac' ]]; then
	plugins+=($mac_plugins)
fi
if [[ $machine_type =~ ':python' ]]; then
	plugins+=($python_plugins)
fi

source $ZSH/oh-my-zsh.sh
fpath=($HOME/lib/zsh/functions $fpath)

## Override things that oh-my-zsh doesn't do right ##
# Turn off the damnable shared history
unsetopt share_history

# Git prompt stuff
autoload -Uz vcs_info
zstyle ':vcs_info:*' stagedstr "%{$fg[green]%}●"
zstyle ':vcs_info:*' unstagedstr "%{$fg[yellow]%}●"
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' enable git svn
precmd() {
	if [[ -z $(git ls-files --other --exclude-standard 2> /dev/null) ]] {
		zstyle ':vcs_info:*' formats "%{$reset_color%}(%{$fg[red]%}%b%{$reset_color%}:%c%u%{$reset_color%}) "
	} else {
		zstyle ':vcs_info:*' formats "%{$reset_color%}(%{$fg[red]%}%b%{$reset_color%}:%c%u%{$fg[white]%}●%{$reset_color%}) "
	}
	vcs_info
}

function git_prompt_info() {
	echo "$vcs_info_msg_0_"
}

# Environment Variables
export PATH=/usr/local/bin:$PATH:/usr/bin:/bin:/usr/sbin:/sbin
export EDITOR=nano
export VISUAL=subl
export PAGER=less
export MYSQL_PS1="\d> "

# set PATH so it includes user's private bin, local/bin and tools
# directories if they exist
if [ -d ~/bin ] ; then
	PATH=~/bin:"${PATH}"
	export PATH
fi
if [ -d ~/local/bin ] ; then
	PATH=~/local/bin:"${PATH}"
	export PATH
fi
if [ -d ~/tools ] ; then
	PATH=~/tools:"${PATH}"
	export PATH
fi


# Python environment variables
if [[ $machine_type =~ ':python' ]]; then
	export PROJECT_HOME="$HOME/projects"
	export PIP_REQUIRE_VIRTUALENV=true
	export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache
	function syspip {
		PIP_REQUIRE_VIRTUALENV="" pip $@
	}
fi

# Mac (and not-mac) things
if [[ $machine_type =~ ':mac' ]]; then
	export LSCOLORS=gxfxbEaEBxxEhEhBaDaCaD
fi

################
# SSH-y things #
################

SSH_ENV="$HOME/.ssh/environment"

# add appropriate ssh keys to the agent
function add_personal_keys {
	# test whether standard identities have been added to the agent already
	if [ -f ~/.ssh/id_rsa ]; then
		ssh-add -l | grep "id_rsa" > /dev/null
		if [ $? -ne 0 ]; then
			ssh-add -t 432000 # Basic ID active for 5 days
			# $SSH_AUTH_SOCK broken so we start a new proper agent
			if [ $? -eq 2 ];then
				start_agent
			fi
		fi
	fi
}

# start the ssh-agent
function start_agent {
	echo "Initializing new SSH agent..."
	# spawn ssh-agent
	ssh-agent | sed 's/^echo/#echo/' > "$SSH_ENV"
	echo succeeded
	chmod 600 "$SSH_ENV"
	. "$SSH_ENV" > /dev/null
	add_personal_keys
}

function reset_ssh_auth {
	if [ -f "$SSH_ENV" ]; then
	. "$SSH_ENV" > /dev/null
	fi
	ps -ef | grep "$SSH_AGENT_PID" | grep ssh-agent > /dev/null
	if [ $? -eq 0 ]; then
		add_personal_keys
	else
		start_agent
	fi
}

# check for running ssh-agent with proper $SSH_AGENT_PID
if [ -n "$SSH_AGENT_PID" ]; then
	ps -ef | grep "$SSH_AGENT_PID" | grep ssh-agent > /dev/null
	if [ $? -eq 0 ]; then
		add_personal_keys
	fi
# if $SSH_AGENT_PID is not properly set, we might be able to load one from
# $SSH_ENV
else
	if [ -f "$SSH_ENV" ]; then
		. "$SSH_ENV" > /dev/null
	fi
	ps -ef | grep "$SSH_AGENT_PID" | grep ssh-agent > /dev/null
	if [ $? -eq 0 ]; then
		add_personal_keys
	else
		start_agent
	fi
fi

