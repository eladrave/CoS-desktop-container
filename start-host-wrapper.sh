#!/usr/bin/env bash
set -Eeuo pipefail

real_start_host=/opt/google/chrome-remote-desktop/start-host.real
config_dir=/home/cos/.config/chrome-remote-desktop
expected_redirect='https://remotedesktop.google.com/_/oauthredirect'

[[ -x "${real_start_host}" ]] || {
  echo "Chrome Remote Desktop start-host binary is unavailable." >&2
  exit 1
}

normalized_args=()
for arg in "$@"; do
  case "${arg}" in
    --redirect-url=*)
      redirect_value="${arg#--redirect-url=}"
      redirect_value="${redirect_value//\\_/_}"
      if [[ "${redirect_value}" == "[${expected_redirect}](${expected_redirect})" ]]; then
        redirect_value="${expected_redirect}"
      fi
      [[ "${redirect_value}" == "${expected_redirect}" ]] || {
        echo "Invalid Chrome Remote Desktop redirect URL." >&2
        exit 2
      }
      normalized_args+=("--redirect-url=${expected_redirect}")
      ;;
    --user-name=cos)
      ;;
    --user-name=*|--corp-user=*|--cloud-user=*)
      echo "This container's Chrome Remote Desktop host must run as local user cos." >&2
      exit 2
      ;;
    *)
      normalized_args+=("${arg}")
      ;;
  esac
done

run_start_host() {
  set +e
  "${real_start_host}" "${normalized_args[@]}"
  status=$?
  set -e
  if compgen -G "${config_dir}/host#*.json" >/dev/null; then
    echo "Chrome Remote Desktop registration is present."
    return 0
  fi
  return "${status}"
}

if [[ "$(id -u)" -eq 0 ]]; then
  exec setpriv     --reuid=10001     --regid=10001     --init-groups     env HOME=/home/cos USER=cos LOGNAME=cos SHELL=/bin/bash     /opt/google/chrome-remote-desktop/start-host "${normalized_args[@]}"
fi

[[ "$(id -u)" -eq 10001 ]] || {
  echo "CRD setup must run as root or local user cos." >&2
  exit 2
}
run_start_host
