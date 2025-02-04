#!/usr/bin/env sh
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'



## Determine if this script is being run locally or from a pipeline:
getLocalSecrets() {
set -x
if test -z "${GITHUB_REPOSITORY}"; then
  set -a
  GITHUB_REPOSITORY=$(git remote get-url origin)
  GITHUB_REPOSITORY="$(echo ${GITHUB_REPOSITORY##https://github.com/} | sed s/\.git//)"
  GITHUB_REF=$(git rev-parse --abbrev-ref HEAD)
  # shellcheck source=local-secrets.sh
  test -f "scripts/local-secrets.sh" && . "scripts/local-secrets.sh" 
  set +a
fi
set +x
}

## Determine environment based on trigger
getEnv() {
  if test -n "${REF}"; then
    # REF is passed in from the pipeline
    ENV="${ENV_PREFIX}${REF}"
    test "${NS_PER_ENV}" = "true" && K8S_NAMESPACE="${NS_PREFIX}${REF}"
  ### This pattern will match if the workflow trigger is prod
  elif test "${GITHUB_REF}" != "${GITHUB_REF%%"${DEFAULT_BRANCH}"}" ; then
    ENV="${ENV_PREFIX}prod"
    test "${NS_PER_ENV}" = "true" && K8S_NAMESPACE="${NS_PREFIX}prod"
  else
  ### This pattern will match if the workflow trigger is a branch
    ENV="${ENV_PREFIX}$(echo "${GITHUB_REF}" | sed -e "s#refs/heads/##g")"
    test "${NS_PER_ENV}" = "true" && K8S_NAMESPACE="${NS_PREFIX}$(echo "${GITHUB_REF}" | sed -e "s#refs/heads/##g")"
  fi
  SERVER_PROFILE_BRANCH="$(echo "${GITHUB_REF}" | sed -e "s#refs/heads/##g")"
  echo "${YELLOW}INFO: Environment is: ${ENV}${NC}"
  export ENV SERVER_PROFILE_BRANCH K8S_NAMESPACE
  setNamespace
}

setNamespace() {
  # Set namespace based on NS_PER_ENV
  kubectl get ns "${K8S_NAMESPACE}" >/dev/null 2>&1
  test $? -ne 0 && kubectl create ns "${K8S_NAMESPACE}"
  kubectl config set-context --current --namespace="${K8S_NAMESPACE}"
}

# End: Set all Global script variables

getGlobalVars() {
  kubectl get cm "${ENV}-global-env-vars" -o=jsonpath='{.data}' | jq -r '. | to_entries | .[] | .key + "=" + .value + ""'
}

# prep for expandFiles
getEnvKeys() {
    env | cut -d'=' -f1 | sed -e 's/^/$/'
}

# process all files that end in .subst to hardcoded files for deployment
envsubstFiles() {

    while true ; do
      echo "${GITHUB_REF}"
      test -z "${1}" && break
      _expandPath="${1}"
      echo "  Processing templates"

      find "${_expandPath}" -type f -iname "*.yaml" > tmpFileList
      rm expandedFiles
      while IFS= read -r template; do
          echo "    t - ${template}"
          _templateDir="$(dirname ${template})"
          _templateBase="$(basename ${template})"
          envsubst "'$(getEnvKeys)'" < "${template}" > "${_templateDir}/${_templateBase}.final"
          echo "${_templateDir}/${_templateBase}.final" >> expandedFiles
      done < tmpFileList
      rm tmpFileList
      shift
    done
}

# for cleanup on local when not dry-run
cleanExpandedFiles() {
  while IFS= read -r file; do
    rm "${file}"
  done < expandedFiles
  rm expandedFiles
}