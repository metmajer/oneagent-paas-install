# PLEASE NOTE THAT THE CODE AND CONTENTS OF THIS REPOSITORY ARE NOT YET READY FOR PRODUCTION USE.

# Dynatrace OneAgent for PaaS Installer

The Dynatrace OneAgent for PaaS installer enables Dynatrace monitoring in environments where installing OneAgent for full-stack monitoring on cluster nodes is not an option.

## Usage

```
./dynatrace-oneagent-paas.sh [flags]
```

## Available Flags

| Name           | Description                           |
|----------------|---------------------------------------|
| `-h`, `--help` | help for `dynatrace-oneagent-paas.sh` |

## Required Environment Variables

| Name           | Description                             |
|----------------|-----------------------------------------|
| `DT_TENANT`    | Your Dynatrace Tenant (Environment ID). |
| `DT_API_TOKEN` | Your Dynatrace API Token.               |

## Optional Environment Variables

### Installation

| Name                     | Description                                                                                                                                   |
|--------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| `DT_CLUSTER_HOST`        | The hostname to your Dynatrace cluster. Defaults to `$DT_TENANT.live.dynatrace.com`. Override if you are running a Dynatrace Managed cluster. |
| `DT_ONEAGENT_PREFIX_DIR` | The installation prefix location (to contain OneAgent in the `dynatrace/oneagent` subdirectory). Defaults to `/var/lib`.                      |

### Technology Support

| Name                  | Description                                                                                                                                           |
|-----------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| `DT_ONEAGENT_BITNESS` | Can be one of (`all` \| `32` \| `64`). Defaults to `64`.                                                                                              |
| `DT_ONEAGENT_FOR`     | Can be any of (`all` \| `apache` \| `java` \| `nginx` \| `nodejs` \| `php` \| `varnish` \| `websphere`) in a comma-separated list. Defaults to `all`. |
| `DT_ONEAGENT_APP`     | The path to an application file. Currently only supported in combination with `DT_ONEAGENT_FOR=nodejs`.                                               |

## Examples

### General

1. Installs OneAgent for all supported technologies into `/var/lib/dynatrace/oneagent`:

```
DT_TENANT=abc DT_API_TOKEN=123 ./dynatrace-oneagent-paas.sh
```

2. Loads OneAgent with your application

Each of the following examples follows the same pattern: you simply integrate OneAgent into your application by prefixing your container command with a script `dynatrace-agent${DT_ONEAGENT_BITNESS}` in `${DT_ONEAGENT_PREFIX_DIR}/dynatrace/oneagent`. **Note**: the actual container command really depends on the inner workings of your container. If you're unsure about which command your container eventually runs, you should inspect your `Dockerfile` or the output of `docker inspect` and search for an entry that begins with `cmd:`.

2.1. Examples: Apache HTTP Server:

```
/var/lib/dynatrace/oneagent/dynatrace-agent64.sh apache2-foreground
```

```
/var/lib/dynatrace/oneagent/dynatrace-agent64.sh httpd -DFOREGROUND
```

2.2. Example: Java application in `/app/app.jar`:

```
/var/lib/dynatrace/oneagent/dynatrace-agent64.sh java -jar /app/app.jar
```

You should always set `DT_ONEAGENT_FOR` to a particular technology to minimize download time and space.

##### NodeJS

Installs OneAgent for the NodeJS technology and integrates it into the application in `/app/index.js`:

```
DT_TENANT=abc DT_API_TOKEN=123 DT_ONEAGENT_FOR=nodejs DT_ONEAGENT_APP=/app/index.js ./dynatrace-oneagent-paas.sh
```

## Testing

We use [Test Kitchen](http://kitchen.ci) together with [Serverspec](http://serverspec.org) to automatically test our installations:

1) Install Test Kitchen and its dependencies from within the project's directory:

```
gem install bundler
bundle install
```

2) Run all tests

```
kitchen test
```

## Disclaimer

This module is supported by the Dynatrace Innovation Lab. Please use the issue tracker to report any problems or ask questions.

## License

Licensed under the MIT License. See the LICENSE file for details.
