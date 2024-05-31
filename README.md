# Table of Contents
1. [Overview](#Overview)
2. [Instructions](#Architecture)
3. [Modernization](#Modernization)


## Overview
This is the installer project for GitHub Runner instances.  


## Design
In it present form, the installer consists of a bash script (./install_runner.sh) and a Helm Chart.  The helm invocation will create the following kubernetes artifacts:
- a deployment
- 1 of 2 secrets (pat or github-app)
- config map

#### Helm Artifacts
> ./Chart.yaml\
./values.yaml\
templates \
├── deployment.yaml\
├── github-app-secret.yml\
├── pat-secret.yaml\
└── pki-configmap.yaml (embedded CA trust bundle)

<br/>

Once the deployment is instantiated, a pod will attempt to register with a GitHub repository.  
To register, it must authenticate either via the PAT or GitHub App.

## Restrictions
Runners in this project are scoped to individual repositories.  This is NOT ideal.  A best case scenario would have runners that are scoped to an organization and reusable across projects.

It looks like it is possible to add a runner to an [Organization Group](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/managing-access-to-self-hosted-runners-using-groups#moving-a-runner-to-a-group).  This would be the ideal scenario.  

A follow on iteration of this project should register the runner with the **Organization Group**.  To accomplish this, you need to have a [GitHub Enterprise Account](https://github.com/home?ef_id=_k_EAIaIQobChMIlKWH5-K4hgMVmCvUAR0KCAxJEAAYAiAAEgKkxfD_BwE_k_&OCID=AIDcmmcwpj1e5v_SEM__k_EAIaIQobChMIlKWH5-K4hgMVmCvUAR0KCAxJEAAYAiAAEgKkxfD_BwE_k_&gad_source=1&gclid=EAIaIQobChMIlKWH5-K4hgMVmCvUAR0KCAxJEAAYAiAAEgKkxfD_BwE).



## Authentication
The runner installation process allows for authentication to GitHub using 1 of 2 methods:

#### GitHub PAT authentication
GitHub PAT authentication requires 3 inputs:

- Personal Access Token
  *  Navigation via GitHub UI:
     *   Profile / Settings / Developer Settings / Personal Access Tokens 
     * Types of Tokens
        * Fine-Grained Token OR
        * Classic Token

> :information_source: You will need to keep a copy of the token, once created.  You only get access to token data once, upon creation.

#### GitHub Application authentication
GitHub Applications are a type of integration that allow granting access to GitHub resources at specific levels.  You can attach GitHub applications to individual GitHub accounts or you can attach a GitHub App to an [Enterprise account](https://docs.github.com/en/enterprise-cloud@latest/apps/creating-github-apps/registering-a-github-app/registering-a-github-app).

This demo uses a GitHub application attached to an individual GitHub Account.  As the enterprise level GitHub App requires a GitHub Enterprise account.



## Instructions

#### Setting up a GitHub application

---

Navigate to: Profile / Settings / Developer Settings / GitHub Apps
Click **New GitHub App** button.

Required fields:
- GitHub App Name
- Homepage URL
- Un-check **Webhook / Active**
- Enable **Only on this account**
- Update repository permissions
- Click **Create GitHub App** button

##### Updating repository permissions
Just set the permissions mentioned in the table below.  This applies RBAC specific to the repository to any process that integrates via the GitHub Application.

<br/>

<table>
  <tr style="background-color:silver;">
    <th>Repository Permission</th>
    <th>Setting</th>
  </tr>
  <tr style="background-color:green;color:white;">
    <td>Administration</td>
    <td>Access: Read and write</td>
  </tr>
  <tr style="background-color:white">
    <td>Checks</td>
    <td>Access: Read and write</td>
  </tr>
  <tr style="background-color:green;color:white">
    <td>Metadata</td>
    <td>Access: Read-only</td>
  </tr>
  <tr style="background-color:white">
    <td>Pull requests</td>
    <td>Access: Read and write</td>
  </tr>
  <tr style="background-color:green;color:white">
    <td>All Others</td>
    <td>Access: No access</td>
  </tr>  
</table>

<br/>

#### Setting the bash execution environment

---

You will need to set env vars based on the type of authentication you select.  

<span style="background-color: yellow;">For PAT authentication you will need:</span>
- **GITHUB_PAT**:   Your individual GitHub account PAT
- **GITHUB_REPO**:  The short name for the repository (ex. `springboot-demo`)
- **GITHUB_OWNER**: The owner of the repository (ex. `abryson-redhat`)

<span style="background-color: yellow;">For GitHub App authentication you will need:</span>
- **GITHUB_APP_ID**:  App Id from the **Edit GitHub App** page  
- **GITHUB_APP_INSTALL_ID**:    See [this article](https://docs.github.com/en/rest/apps/installations?apiVersion=2022-11-28)
- **GITHUB_APP_PEM**: Contents of Pem file.  Private key generated from the **Edit GitHub App** page.  
> :warning: You must generate a private key at the bottom of the Edit page.  It will download a `.pem` file

Additionally, **GITHUB_REPO** and **GITHUB_OWNER** are required.

#### Executing the bash script

---

##### Usage
```bash
./install_runner.sh <helm release name> <runner label names> <runner image pull spec> 
```

- release name will also be used to prefix the deployment and pod resource names
- runner label names are registered to GitHub
  * can be used by GitHub workflows in a `runs-on:` clause
- runner image pull spec (ex. `quay.io/abryson/buildah-runner`)
<br/>

> **example call:**
```bash
./install_runner.sh "actions-runner-java-runtime-11" "{local,java-runtime}" "quay.io/abryson/java-runtime-11-runner"
```

#### Verification

---

Check that you have a runner pod executing in the desired namespace.  I created a **github** namespace for housing all github related integration artifacts.

```bash
oc get pods -n github
```

You might additionally check the pod logs.
```bash
oc logs -f <pod name>
```

Once the pod is ready, it will indicate it is listening for GitHub requests.


## Modernization
This application may be adapted to work in a GitOps framework.  If using ArgoCD, you might create an Application resource that invokes the Helm installation, bypassing the script.

This will take some planning, as there are many dependencies that need to be in place for the execution to succeed.  Additionally, you want to trigger this process after you've updated an existing runner image or created a new runner image. 

The custom runner images are part of [another project](https://github.com/abryson-redhat/custom-github-runners).

