#compdef nb
###############################################################################
# __          _
# \ \   _ __ | |__
#  \ \ | '_ \| '_ \
#  / / | | | | |_) |
# /_/  |_| |_|_.__/
#
# `nb` · `notes` && `bookmark`
#
# Command line note-taking, bookmarking, and archiving with encryption, search,
# Git-backed versioning and syncing, Pandoc-backed format conversion, and more
# in a single portable script.
#
# https://github.com/xwmx/nb
###############################################################################
_nb_subcommands() {
  # _nb_cache_completions()
  #
  # Usage:
  #   _nb_cache_completions <path>
  #
  # Description:
  #   Cache completions for `nb`. Generating completions can be slow and
  #   native shell caching doesn't appear to help.
  _nb_cache_completions() {
    local _cache_path="${1:-}"

    [[ -z "${_cache_path:-}" ]] && return 0

    # Remove outdated cache files.

    local _base_cache_path="${_cache_path%-*}"
    local __suffix

    for __suffix in "zsh" "v1"
    do
      if [[ -e "${_base_cache_path:?}-${__suffix:?}" ]]
      then
        rm -f  "${_base_cache_path:?}-${__suffix:?}"
      fi
    done

    # Rebuild completion cache.

    local _commands
    IFS=$'\n' _commands=($(nb subcommands))

    local _notebooks
    IFS=$'\n' _notebooks=($(nb notebooks --names --no-color --unarchived))

    local _filenames
	#IFS=$'\n' _filenames=($(nb ls --filenames | cut -d ' ' -f 2))
	# the field number is unknown : plain or encrypted files ?
	# you need awk to get the last field
	IFS=$'\n' _filenames=($(nb ls --filenames | awk '{print $NF}'))

    local _completions=()
	IFS=$'\n' _completions=(${_commands[@]} ${_filenames[@]})

    local _commands_cached=
    local _notebooks_cached=
    local _filenames_cached=

    if [[ -e "${_cache_path}" ]]
    then
      local _counter=0

      while IFS= read -r __line
      do
        _counter=$((_counter+1))

        if [[ "${_counter}" == 1 ]]
        then
			IFS=$' ' _commands_cached=("${__line}")
        elif [[ "${_counter}" == 2 ]]
        then
			IFS=$' ' _notebooks_cached=("${__line}")
        elif [[ "${_counter}" == 3 ]]
        then
			IFS=$' ' _filenames_cached=("${__line}")
        else
          break
        fi
      done < "${_cache_path}"
    fi

    if [[ "${_commands_cached}"  != "${_commands:-}"   ]] ||
       [[ "${_notebooks_cached}" != "${_notebooks:-}"  ]] ||
       [[ "${_filenames_cached}" != "${_filenames:-}"  ]]
    then
      # Construct <notebook>:<subcommand> completions.
      for __notebook in "${_notebooks[@]}"
      do
        for __command in "${_commands[@]}"
        do
          if [[ -n "${__notebook:-}" ]] && [[ -n "${__command:-}" ]]
          then
            _completions+=("${__notebook}:${__command}")
          fi
        done
      done

      local _directory_path
      _directory_path="$(dirname "${_cache_path}")"

      mkdir -p "${_directory_path}"

      if [[ -f "${_cache_path:?}" ]]
      then
        rm -f "${_cache_path:?}"
      fi

      touch "${_cache_path:?}"

      {
        (IFS=$' '; printf "%s\\n" "${_commands[*]}")
        (IFS=$' '; printf "%s\\n" "${_notebooks[*]}")
        (IFS=$' '; printf "%s\\n" "${_filenames[*]}")
        printf "%s\\n" "${_completions[@]}"
      } >> "${_cache_path}"

    fi
  }

  local _nb_dir=
  _nb_dir="$(nb env | grep 'NB_DIR' | cut -d = -f 2)"

  if [[ -z "${_nb_dir:?}"  ]] ||
     [[ ! -e "${_nb_dir}"  ]]
  then
    return 0
  elif [[ -L "${_nb_dir}" ]]
  then
    if hash "realpath" 2>/dev/null
    then
      _nb_dir="$(realpath "${_nb_dir}")"
    else
      _nb_dir="$(readlink "${_nb_dir}")"
    fi
  fi

  if [[ ! -d "${_nb_dir}"  ]]
  then
    return 0
  fi

  local _cache_path="${_nb_dir:?}/.cache/nb-completion-cache-v2"
  local _completions_cached=()

  if [[ ! -e "${_cache_path}" ]]
  then
    _nb_cache_completions "${_cache_path}"
  fi

  if [[ -e "${_cache_path}" ]]
  then
    _nb_cache_completions "${_cache_path}"

    local _counter=0

    while IFS= read -r __line
    do
      _counter=$((_counter+1))

      if [[ "${_counter}" -gt 3 ]]
      then
        _completions_cached+=("${__line}")
      fi
    done < "${_cache_path}"

    #(_nb_cache_completions "${_cache_path}" &)
  fi

  if [[ "${?}" -eq 0 ]]
  then
	compadd -- "${_completions_cached[@]}"
	return 0
  else
    return 1
  fi
}

_nb_subcommands "$@"
