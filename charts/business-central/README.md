# Microsoft Dynamics 365 Business Central



![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  ![AppVersion: 16.5.15897.15953](https://img.shields.io/badge/AppVersion-16.5.15897.15953-informational?style=flat-square) 

> Streamline your processes, make smarter decisions, and accelerate growth with Dynamics 365 Business Central — a comprehensive business management solution designed for small to medium-sized businesses.
>
> -- <cite>[Business Central Product Page](https://dynamics.microsoft.com/en-us/business-central/overview/)</cite>

This is an **unofficial** Helm chart for running Microsoft Dynamics 365 Business Central on Kubernetes.

## Prerequisites

- Kubernetes: `>= 1.18.0`
- Windows nodes in your cluster

## TL;DR;

If you use a managed Kubernetes cluster or your on-premises cluster supports `LoadBalancer` services, the easiest way to install with the default configuration (image requiring Windows Server 2019 build `10.0.17763.1397` or newer) is:
```
helm repo add lippertmarkus https://charts.lippertmarkus.com
helm install my-release lippertmarkus/business-central --set service.type=LoadBalancer
```
Follow the instructions displayed after the installation on how to get the external IP to access the Business Central web client. 

Have a look at the [common scenarios section](#common-scenarios) to quickly get familiar with the core possibilities of this chart.

## Introduction

This chart deploys Microsoft Dynamics 365 Business Central based on the [official Docker images from Microsoft](https://github.com/microsoft/nav-docker/). It aims to simplify deployment of Business Central within a cluster.

It supports using [Business Central artifacts](https://freddysblog.com/2020/06/25/changing-the-way-you-run-business-central-in-docker/) to set up the desired version on-demand as well as pre-built images. Further you can easily secure your passwords, use an external database, use custom scripts to override the default behavior, setup access via ingress or a load balancer and automatically download and publish AL extensions on startup.

## Installing the Chart

To install the chart with the release name `myrelease` and the default configuration (image requiring Windows Server 2019 build `10.0.17763.1397` or newer) use:
```
helm repo add lippertmarkus https://charts.lippertmarkus.com
helm install myrelease lippertmarkus/business-central
```

The default configuration only allows cluster-internal access to your Business Central instance (`ClusterIP` service). Follow the instructions displayed after the installation on how to use `kubectl port-forward` to gain access.

For external access you may want to use ingress, a load balancer or expose the service via your node ports by configuring `ingress.*` or `service.type`. 

## Uninstalling the Chart

For uninstalling your release `myrelease` execute:
```
helm uninstall myrelease lippertmarkus/business-central
```

This removes all resources from your cluster.

## Common Scenarios

The next sections describe some common scenarios and the required configuration for them. While you can directly specify configuration parameters on `helm install` with `--set`, the next sections also show parts of configuration files which can be used on installation like:
```
helm install myrelease lippertmarkus/business-central -f config.yml
```

You can find a detailed explanation of all the presented configuration options within the [configuration reference](#configuration).

### Accessing Business Central

There are four ways for accessing Business Central:

- The default configuration only allows **cluster-internal** access to your Business Central instance (`ClusterIP` service). Follow the instructions displayed after the installation on how to use `kubectl port-forward` to gain access.

- If you use a managed Kubernetes cluster or your on-premises cluster supports **`LoadBalancer`** services, the easiest way to set up external access is to set `service.type` to `LoadBalancer`. Follow the instructions displayed after the installation on how to get the external IP to access the Business Central web client.

- You can also access Business Central **via ports of the nodes** in your cluster by setting `service.type` to `NodePort`. Follow the instructions displayed after the installation on how to get the port to access the Business Central web client via your Nodes. 

- Using **Ingress** is another option. If you already have an [ingress controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/) deployed you can just enable the ingress option and define the hosts where the web client and web service endpoints should be accessible at:
  ```yaml
  ingress:
    enabled: true
    hosts:
      - host: bc1.example.com
        path: /  # optional, use a sub path
        servicePort: web
      - host: dev.bc1.example.com
        servicePort: dev
  ```

### Using artifacts and pre-built images

There are many versions of Business Central as well as monthly updates. Beyond there's a requirement for Windows Containers that the Windows version of the base image of a container must match the version of the host OS (when using process isolation).

Instead of providing images for each Business Central version on each Windows version, Microsoft [decided](https://freddysblog.com/2020/06/25/changing-the-way-you-run-business-central-in-docker/) to instead provide *generic images* for each Windows version as well as artifacts for installing Business Central onto those generic images. You can either use the artifact to create your own images based on the generic image or use the generic image directly and specify the artifacts which get downloaded and installed at startup.

To use the **generic image and artifacts**, set:
```yaml
image:
  repository: mcr.microsoft.com/dynamicsnav
  tag: "10.0.17763.1397-generic"
  artifactUrl: "https://bcartifacts.azureedge.net/onprem/16.5.15897.15953/w1"
```

There's [a list of available tags](https://mcr.microsoft.com/v2/dynamicsnav/tags/list) where you should look after `*-generic` for the generic images. `*` should match the OS version of the Windows nodes within your cluster. Tags of the same Windows version but an [older build number also work fine](https://docs.microsoft.com/en-US/virtualization/windowscontainers/deploy-containers/version-compatibility#revision-number-patching).

For getting the artifact URL you can use the [BcContainerHelper PowerShell module](https://www.powershellgallery.com/packages/BcContainerHelper/) with the `Get-BcArtifactUrl` Cmdlet like described [here](https://freddysblog.com/2020/06/25/working-with-artifacts/).

If you want to use **pre-built images** instead, just set your own image and remove the artifact URL:
```yaml
image:
  repository: myrepo/myimage
  tag: "16.5.15897.15953-w1"
  artifactUrl: ""
```

You can build your own image with the `New-BcContainer` Cmdlet of the BcContainerHelper PowerShell module like described [here](https://freddysblog.com/2020/06/25/working-with-artifacts/).

### Using external databases

When using a generic image and artifacts there's a demonstration database available. If you use your own pre-built images you could also add your own database to the image.

Instead of using those databases you can further use an external database:
```yaml
database:
  custom: true
  server: "myserver.database.windows.net"
  instance: ""  # use default SQL server instance
  name: "cronus"
  username: "sa"
  #password: ""  # insecure plaintext password, use encrypted password below is recommended
  securePassword: "76492d1116743f042..."

passwordKeySecretName: "mysecret"   # only needed with database.securePassword
```

Details on how to encrypt your password are explained in the next section.

### Setting a password

When you don't set a password, a random one will be generated for the admin user. This isn't secure but helps you getting started quickly. You can set a specific password by using one of the following:
```yaml
#password: ""  # insecure plaintext password, using encrypted password below is recommended
securePassword: "76492d1116743f042..."

passwordKeySecretName: "mysecret"  # only needed with securePassword
```

To create a new AES key, encrypt a password with it and store the key within a Kubernetes secret you can use the following PowerShell code:
```powershell
# Create a new key
$passwordKey = New-Object Byte[] 16
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($passwordKey)

# Store the key within a Kubernetes secret
kubectl create secret generic mysecret --from-literal=passwordKey=$passwordKey

# Encrypt our password with the key
$securePassword = ConvertFrom-SecureString -SecureString (Get-Credential).Password -Key $passwordKey
```

Within the chart configuration you now set `passwordKeySecretName` to the name of the secret you created and `securePassword` or `database.securePassword` to your encrypted password stored in `$securePassword`.

### Modifying default behavior

The official image of Business Central [allows modifying the default behavior](https://github.com/microsoft/nav-docker/blob/master/HOWTO.md#appendix-1--scripts) by adding custom script with the same filename as the original ones which are then called instead. You can easily add those scripts like in the following:
```yaml
customScripts:
  AdditionalSetup.ps1: |-
    if ($true) {
        Write-Host "This was created by Kubernetes."
    }
```

### Configuration via environment variables

There are [a lot of environment variables](https://github.com/microsoft/nav-docker/blob/master/generic/Run/SetupVariables.ps1) you can use for configuring the Business Central container. Some of them like the ones for using external databases, specifying (secure) passwords and artifacts are set through the exposed Helm configuration parameters described before for simplicity. You can set the other ones in `env`:

```yaml
env:
  username: admin
  HttpSite: "N"
  # ...
```

### Automatically publishing AL extensions on startup (experimental)

If you deploy a Business Central environment you often also want to deploy an AL extension. To automate this as well you can use the publish option of the chart. The two default images are used to first download AL extensions from a NuGet feed and afterwards deploy them via the development endpoint.

To use this you need to configure which NuGet feed to use and which AL extensions should be downloaded:
```yaml
publish:
  enabled: true
  download:
    params: 
      nugetLocation: "https://myorg.pkgs.visualstudio.com/myproj/_packaging/myfeed/nuget/v3/index.json"
      patSecretName: "mypat"
      dependencies:
        # This downloads two NuGet Packages Comp_AppName and Comp_AppName2 with the version 1.2.3.4
        - publisher: Comp
          name: AppName
          version: "1.2.3.4"
        - publisher: Comp
          name: AppName2
          version: "1.2.3.4"
```

For access to the NuGet feed you need to create a personal access token and store it within a Kubernetes secret referenced in `publish.download.params.patSecretName`:
```
kubectl create secret generic mypat --from-literal=pat=MwBEAE...
```

### Disabling access to endpoints

For some environments you may want to disable external access to some endpoints like the ones for development, OData or SOAP. Per default all endpoints can be accessed. By setting the port of specific endpoints to an empty string, you can disable the access:
```yaml
service:
  ports:
    # access to web client is still allowed (default configuration values)
    soap: ""  # disable SOAP
    odata: ""  # disable OData
    dev: ""  # disable development endpoint
    dl: ""  # disable file access endpoint
```

## Configuration Reference

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Constrain which nodes the workload is eligible to be scheduled on, see [Kubernetes docs](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity). |
| customScripts | object | `{"AdditionalSetup.ps1":"Write-Host \"This was created by Kubernetes.\""}` | Add custom PowerShell scripts to the container. They can override the default scripts like described [here](https://github.com/microsoft/nav-docker/blob/master/HOWTO.md#appendix-1--scripts). |
| database.custom | bool | `false` | Enable to connect to an external SQL server with a Business Central database. |
| database.instance | string | `""` | SQL Server instance to connect to, e.g. `SQL2019`. Leave empty to use the default instance. |
| database.name | string | `""` | Name of the database to connect to, e.g. `cronus`. |
| database.password | string | `""` | **Insecure** clear-text password of the user to connect with. Consider using `database.securePassword` and `passwordKeySecretName` instead. |
| database.securePassword | string | `""` | AES-encrypted password of the user to connect with. Requires `passwordKeySecretName` to be set. See [here](#TODO) on how this works. |
| database.server | string | `""` | SQL Server to connect to, e.g. `myserver.database.windows.net`. |
| database.username | string | `""` | User used to connect to the SQL database, e.g. `sa`. |
| env | object | *The two variables below are set per default* | Configure application via environment variables. See `values.yaml` for more options you can add. |
| env.Accept_eula | string | `"Y"` | Whether to accept (`Y`) or decline (`N`) the [EULA](https://go.microsoft.com/fwlink/?linkid=861843). |
| env.UseSSL | string | `"N"` | Whether to use SSL for the webclient (`Y`) or not (`N`). If set to `Y` generates a self-signed certificate per default. |
| fullnameOverride | string | `""` | Override the full name of the deployment, e.g. `myfullnameoverride`. |
| image.artifactUrl | string | `"https://bcartifacts.azureedge.net/onprem/16.5.15897.15953/w1"` | URL of the Business Central artifacts to download and setup on startup. Use `""` if you use a pre-built image in `image.repository`. See [here](#TODO) for mor information. around the two options. |
| image.pullPolicy | string | `"IfNotPresent"` | Whether to `Always` try pulling the image or only `IfNotPresent`. |
| image.repository | string | `"mcr.microsoft.com/dynamicsnav"` | Repository of the image to use. You can use a generic image and set `image.artifactUrl` or use a pre-built image and set `image.artifactUrl` to `""`. See [here](#TODO) for mor information. around the two options. |
| image.tag | string | `"10.0.17763.1397-generic"` | Tag of the image to use |
| imagePullSecrets | list | `[]` | List with Kubernetes secrets for pulling images from private repositories. See [docs](https://kubernetes.io/docs/concepts/containers/images/#referring-to-an-imagepullsecrets-on-a-pod). |
| ingress.annotations | object | `{}` | Annotations to add to the ingress resource, e.g. `kubernetes.io/tls-acme: "true"` |
| ingress.enabled | bool | `false` | Enable to allow access via [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/#what-is-ingress). |
| ingress.hosts | list | `[]` | List of hosts with `host`, `path` and `servicePort` which the ingress routes to the Business Central instance. See [Kubernetes docs](https://kubernetes.io/docs/concepts/services-networking/ingress/#the-ingress-resource). E.g. `[{"host":"bc1.example.com","path":"/","servicePort":"web"}]` routes traffic from `http://bc1.example.com/` to the webclient. Using a subpath in `path` may requires [rewriting via annotations](https://kubernetes.github.io/ingress-nginx/examples/rewrite/). The `servicePort` can be one of `web`, `webtls`, `odata`, `soap`, `dev`, `dl` described under `service.ports.*`. |
| ingress.tls | list | `[]` | List of secrets with a TLS certificate and hosts from `ingress.hosts` to use the certificate for. See [Kubernetes docs](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls). E.g. `[{"hosts":["bc1.example.com"],"secretName":"example-tls"}]` |
| nameOverride | string | `""` | Override the name of the Helm deployment which the chart name gets prefixed with, e.g. `myoverride-business-central`. |
| nodeSelector | object | *see below* | Use to select specific nodes to schedule the deployment to like described in the Kubernetes [docs](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector). |
| nodeSelector."kubernetes.io/os" | string | `"windows"` | OS to schedule the deployment to. |
| password | string | `""` | **Insecure** clear-text password of the admin user. Leave empty for a random password. Consider using `securePassword` and `passwordKeySecretName` instead. |
| passwordKeySecretName | string | `""` | Name of the Kubernetes secret which contains the AES key within `passwordKey` for decrypting `secretPassword` or `database.secretPassword`. See [here](#TODO) on how this works. |
| podAnnotations | object | `{}` | [Annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) to add to the metadata of the Pods. |
| podSecurityContext | object | `{}` | Configure the [security context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) of the Pod. |
| publish | object | *see below* | **EXPERIMENTAL**: Automatically download an AL app with `publish.download.image.*` and publish it with `publish.image.*` |
| publish.affinity | object | `{}` | Constrain which nodes the publish job is eligible to be scheduled on, see [Kubernetes docs](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity). |
| publish.download.image.pullPolicy | string | `"Always"` | Whether to `Always` try pulling the image or only `IfNotPresent`. |
| publish.download.image.repository | string | `"lippertmarkus/al-nuget"` | Repository of the image to use for downloading AL app files. |
| publish.download.image.tag | string | `"latest"` | Tag of the image to use. |
| publish.download.params | object | *see below* | Parameters for downloading the AL app files. This is currently specific for `lippertmarkus/al-nuget`. |
| publish.download.params.dependencies | list | `[]` | AL app files to download from NuGet. This get's passed as JSON to the container. E.g. `[{"name":"AppName","publisher":"Comp","version":"1.2.3.4"}]` for downloading a package `Comp_AppName` with version `1.2.3.4` |
| publish.download.params.nugetLocation | string | `""` | URL of the NuGet feed to use, e.g. `https://myorg.pkgs.visualstudio.com/myproj/_packaging/myfeed/nuget/v3/index.json` |
| publish.download.params.patSecretName | string | `""` | Name of the Kubernetes secret with a `pat` field containing a personal access token for accessing the NuGet feed. |
| publish.enabled | bool | `false` | Whether to enable automatically downloading AL app files and publish them |
| publish.image.pullPolicy | string | `"Always"` | Whether to `Always` try pulling the image or only `IfNotPresent`. |
| publish.image.repository | string | `"lippertmarkus/bc-app-import"` | Repository of the image to use for importing AL app files. |
| publish.image.tag | string | `"latest"` | Tag of the image to use. |
| publish.nodeSelector | object | *see below* | Use to select specific nodes to schedule the publish job to like described in the Kubernetes [docs](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector). |
| publish.nodeSelector."kubernetes.io/os" | string | `"linux"` | OS to schedule the publish job to. |
| publish.tolerations | list | `[]` | List with [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) the publish job has. |
| replicaCount | int | `1` | Number of replicas to deploy. |
| resources | object | `{}` | Limit [CPU](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/#specify-a-cpu-request-and-a-cpu-limit) and [memory](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/#specify-a-memory-request-and-a-memory-limit) resources this workload can use. |
| securePassword | string | `""` | AES-encrypted password of the admin user. Requires `passwordKeySecretName` to be set. See [here](#TODO) on how this works. |
| securityContext | object | `{}` | Configure the [security context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) of the Container. |
| service.ports.dev | int | `7049` | Port of the service to access the development endpoint. Remove to disable access. |
| service.ports.dl | int | `8080` | Port of the service to access the files like the AL VS code extension via web. Remove to disable access. |
| service.ports.odata | int | `7048` | Port of the service to access the OData webservice. Remove to disable access. |
| service.ports.soap | int | `7047` | Port of the service to access the SOAP webservices. Remove to disable access. |
| service.ports.web | int | `80` | Port of the service to access the web client. Remove to disable access. |
| service.ports.webtls | int | `443` | Port of the service to access the web client via TLS. Remove to disable access. |
| service.type | string | `"ClusterIP"` | [Type of the service](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) which exposes Business Central, e.g. `ClusterIP`, `LoadBalancer` or `NodePort`. |
| serviceAccount.name | string | `""` | The name of the [service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) to use. |
| tolerations | list | `[]` | List with [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) this workload has. |