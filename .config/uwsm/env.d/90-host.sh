# Per-machine graphical-session environment.
#
# uwsm sources uwsm/env, then uwsm/env.d/*, then uwsm/env-<desktop>* — so this
# fragment runs after the shared defaults in uwsm/env: any value set here wins.
#
# It applies the same host layer that ~/.zprofile sources for login shells, so
# shells and the session share one source of truth per machine:
#   ~/.config/env/<hostname>/*

# Fallback for contexts where the login shell's export is not present.
ENV_HOME="${ENV_HOME:-$HOME/.config/env}"

_h=$(uname -n)
_d="${ENV_HOME}/${_h}"
if [ -d "${_d}" ]; then
	for _f in "${_d}"/*; do
		case "${_f}" in
		*.bak | *~ | *.disabled | *.example | *.sample | *.broken) continue ;;
		esac
		[ -f "${_f}" ] && . "${_f}"
	done
fi
unset _h _d _f
