# Authorization from Step 2:
# Either GITHUB_PAT, OR all 3 of GITHUB_APP_*
# prerequisites
#    env vars:
#   GITHUB_PAT     - set to your GITHUB_PAT
#   GITHUB_REPO    - the repo short-name of the github project (ex. springboot-demo) 
#   GITHUB_OWNER   - the owner of the repo (ex. abryson-redhat)
# sample usage:
#   $ ./install_runner.sh "actions-runner-image-scan" "{local,image-scan}" "quay.io/abryson/imagescan-runner"

# OR, GitHub App information:
#export GITHUB_APP_ID=855509
#export GITHUB_APP_INSTALL_ID=48459756
#export GITHUB_APP_PEM='----------BEGIN RSA PRIVATE KEY...'
#export GITHUB_APP_PEM=$(cat /home/abryson/Downloads/smbc-demo-sonar.2024-03-18.private-key.pem)

# For an org runner, this is the org.
# For a repo runner, this is the repo owner (org or user).
#export GITHUB_OWNER=redhat-actions
# For an org runner, omit this argument.
# For a repo runner, the repo name.
#export GITHUB_REPO=openshift-actions-runner-chart
# Helm release name to use.
#export RELEASE_NAME=actions-runner-java

# helm release name
export RELEASE_NAME=$1

# label names for the runner:  array in {label1, label2) form
export RUNNER_LABELS=$2

# input image name - ex. "quay.io/abryson/java-build-11-runner"
export RUNNER_IMAGE=$3
export RUNNER_TAG="latest"

# If you cloned the repository (eg. to edit the chart)
# replace openshift-actions-runner/actions-runner below with the directory containing Chart.yaml.

# Installing using PAT Auth
## buildah requires a rootless execution.  it requires a special service account
##   steps to setup:
##   oc create sa buildah-sa
##   oc adm policy add-scc-to-user anyuid -z buildah-sa
##   oc secrets link buildah-sa <pull-secret> --for=pull
if [[ ${RUNNER_LABELS} == *"buildah"* ]]; then
  helm install -f ./values.yaml $RELEASE_NAME . \
      --set-string githubPat=$GITHUB_PAT \
      --set-string githubOwner=$GITHUB_OWNER \
      --set-string githubRepository=$GITHUB_REPO \
      --set-string runnerImage=$RUNNER_IMAGE \
      --set-string runnerTag=$RUNNER_TAG \
      --set runnerLabels="${RUNNER_LABELS}" \
      --set serviceAccountName=buildah-sa
else
  helm install -f ./values.yaml $RELEASE_NAME . \
      --set-string githubPat=$GITHUB_PAT \
      --set-string githubOwner=$GITHUB_OWNER \
      --set-string githubRepository=$GITHUB_REPO \
      --set-string runnerImage=$RUNNER_IMAGE \
      --set-string runnerTag=$RUNNER_TAG \
      --set runnerLabels="${RUNNER_LABELS}"
fi
echo "---------------------------------------" \
&& helm get manifest $RELEASE_NAME | kubectl get -f -

# OR, Installing using App Auth
#helm install $RELEASE_NAME openshift-actions-runner/actions-runner \
#    --set-string githubAppId=$GITHUB_APP_ID \
#    --set-string githubAppInstallId=$GITHUB_APP_INSTALL_ID \
#    --set-string githubAppPem="$GITHUB_APP_PEM" \
#    --set-string githubOwner=$GITHUB_OWNER \
#    --set-string githubRepository=$GITHUB_REPO \
#&& echo "---------------------------------------" \
#&& helm get manifest $RELEASE_NAME | kubectl get -f -

