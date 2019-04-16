# Installing Syndesis on Demo Cluster

Just run:
```
./deploy.sh
```

## Rebuilding the images

If needed, images can be rebuilt from source:

- Camel K Runtime (no images, just needed libs): https://github.com/rhdemo/camel-k-runtime/blob/summit-2019/SUMMIT-2019.md
- Syndesis: https://github.com/rhdemo/syndesis/blob/summit-2019-1.6.x/SUMMIT-2019.md
- Camel K: https://github.com/rhdemo/camel-k/blob/summit-2019/SUMMIT-2019.md

Tools required:
- https://stedolan.github.io/jq/
- https://github.com/mikefarah/yq

syndesis-server-config
```yaml
    resource:
      update:
        controller:
          enabled: false
    controllers:
      integration: camel-k
      maxIntegrationsPerUser: 50
      maxDeploymentsPerUser: 50
      integrationStateCheckInterval: 60
      dblogging:
        enabled: false
      camelk:
        environment:
          DATAGRID_SERVICE_HOST: datagrid-service.datagrid-demo.svc.cluster.local
          DATAGRID_SERVICE_PORT: 11222
          DATAGRID_CACHE_NAME: camel-salesforce
```

syndesis-ui-config
```
"branding": {
    "logoWhiteBg": "",
    "logoDarkBg": "",
    "iconWhiteBg": "assets/images/FuseOnlineLogo_Black.svg",
    "iconDarkBg": "assets/images/FuseOnlineLogo_White.svg",
    "appName": "Ignite",
    "favicon32": "/favicon-32x32.png",
    "favicon16": "/favicon-16x16.png",
    "touchIcon": "/apple-touch-icon.png",
    "productBuild": true
 }
 ```
