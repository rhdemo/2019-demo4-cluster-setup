# Datagrid Service
Scripts to install DG 7.3 in the `datagrid-demo` project.

## Default Configuration
- Uses official 7.3 image
- Distributed mode
    - Each key/value is distributed across two nodes
- Entries stored off-heap

## Endpoints
- CONSOLE
    - service = datagrid-service
    - route = console-datagrid-demo.6923.rh-us-east-1.openshiftapps.com

- REST
    - service = datagrid-service
    - route = rest-datagrid-demo.apps.dev.openshift.redhatkeynote.com:8443

- HOTROD
    - service = datagrid-service
    - route = hotrod-datagrid-demo.apps.dev.openshift.redhatkeynote.com:11222

All services can be reached directly via:
`datagrid-service.datagrid-demo.svc.cluster.local`

### Usage
Configured user credentials:
```
USER=admin
PASS=admin
```
Both endpoints are configured with authentication enabled. Example hotrod clients, with the configuration settings required to connect to this service, can be found [here](https://github.com/rhdemo/2019-datagrid-client-examples). Additional examples can also be found in the [JDG quickstarts repo](https://github.com/jboss-developer/jboss-jdg-quickstarts/tree/jdg-7.3.x/openshift).

## Cache Configurations
Additional cache configurations can be added to `config/standalone.xml` as required by issuing a PR or contacting `remerson`.

## Machine Counter Configurations
Currently we have 20 machine counters configured, which follow the naming convention `machine-x` from 1-20. All of the counters have the following configuration:

```xml
<counters reliability="CONSISTENT">
    <strong-counter name="machine-1" initial-value="1000000000000000000" storage="VOLATILE">
        <lower-bound value="0"/>
        <upper-bound value="1000000000000000000"/>
    </strong-counter>
</counters>
```

The important characteristics are that the stored value is VOLATILE, i.e only in memory. Also, all of the counters are CONSISTENT, which means in the event of network partition, only clients which are able to connect to the majority partition will be able to update
the counter's value until the partition has healed.
