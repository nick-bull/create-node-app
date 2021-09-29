#!/bin/sh

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

script_name="$(__path_resolve "$0")"
script_dir="$(dirname "${script_name}")"
app_dir="$(dirname "${script_dir}")"
app_parent_dir="$(dirname "${app_dir}")"
config_path="${script_dir}/config.txt"

for config_variable in "APP_NAME" "APP_SCOPE" "AUTHOR_USERNAME"; do
  if ! grep -q "^${config_variable}=.\{1,\}" "${config_path}"; then
    echo "Configuration variable '${config_variable}' must be set in '${config_path}"
    exit 1
  fi
done

if ! grep -q "^APP_URL=.\{1,\}" "${config_path}"; then
  cat "${config_path}"

  echo "Configuration variable 'APP_URL' is not set in '${config_path}'"
  echo "This will cause errors when running Ansible"

  printf "Continue? [y/N]: "
  read answer
  case "$answer" in
    y|Y) ;;
    *)
      echo "Aborted"
      exit 1

      ;;
  esac
fi

while IFS="" read -r line || [ -n "$line" ]; do
  conf_variable="${line%%=*}"
  conf_value="${line#*=}"

  test "${conf_variable}" = "APP_NAME" && app_name="${conf_value}"
  test "${conf_variable}" = "APP_SCOPE" && app_scope="${conf_value}"
  test "${conf_variable}" = "APP_DESCRIPTION" && app_description="${conf_value}"
  test "${conf_variable}" = "AUTHOR_USERNAME" && author_username="${conf_value}"

  echo "Replacing '{{${conf_variable}}}' with '${conf_value}'"

  find "${app_dir}" -type f -exec sed -i 's|{{'"${conf_variable}"'}}|'"${conf_value}"'|g' {} \;
done < "${config_path}"

find "${app_dir}" -type f -exec sed -i 's|{{APP_PWD}}|'"${app_dir}"'|g' {} \;

new_app_dir="${app_parent_dir}/${app_name}"

cd "${new_app_dir}"
rm -r "${new_app_dir}"/initialise

npm i

git add .
git commit -m 'Initialised npm app'

git remote add origin git@github.com:"${author_username}"/"${app_name}".git

