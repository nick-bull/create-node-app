#!/bin/sh

# __path_resolve 
#
# LIMITATIONS
#   - Won't work with filenames with embedded newlines or filenames containing
#     the string ' -> '.
#
__path_resolve() ( # Execute the function in a subshell to localize side effects.
  target=$1 fname= targetDir= CDPATH=

  { \unalias command; \unset -f command; } >/dev/null 2>&1

  # make zsh find *builtins* with `command` too.
  test -n "$ZSH_VERSION" && options[POSIX_BUILTINS]=on 

  while :; do # Resolve potential symlinks until the ultimate target is found.
      if ! test -L "$target" && ! test -e "$target"; then 
        command printf '%s\n' "ERROR: '$target' does not     exist." >&2;
        return 1;
      fi

      # Change to target dir; necessary for correct     resolution of target path.
      command cd "$(command dirname -- "$target")"

      fname=$(command basename -- "$target") # Extract filename.
      test "$fname" = '/' && fname='' # !! curiously, `basename /` returns '/'

      if test -L "$fname"; then
        # Extract [next] target path, which may be defined
        # *relative* to the symlink's own directory.
        # Note: We parse `ls -l` output to find the symlink target
        #       which is the only POSIX-compliant, albeit somewhat fragile, way.
        target=$(command ls -l "$fname")
        target=${target#* -> }

        continue
      fi

      break
  done

  targetDir=$(command pwd -P) # Get canonical dir. path
  # Output the ultimate target's canonical path.
  # Note that we manually resolve paths ending in /. and /.. to make sure we have a normalized pa    th.

  if test "$fname" = '.'; then
    command printf '%s\n' "${targetDir%/}"
  elif test "$fname" = '..'; then
    # Caveat: something like /var/.. will resolve to /private (assuming /var@ -> /private/var)
    # AFTER canonicalization.
    command printf '%s\n' "$(command dirname -- "${targetDir}")"
  else
    command printf '%s\n' "${targetDir%/}/$fname"
  fi
)

resolved_create_script_path="$(__path_resolve "./create-node-app.sh")"
sudo ln -s "${resolved_create_script_path}" /usr/bin/create-node-app

