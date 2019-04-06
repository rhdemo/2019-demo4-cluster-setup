/*
kamel run \
    --dev \
    --name damage-service \
    --profile openshift \
    --dependency camel-netty4-http \
    --dependency camel-infinispan \
    --dependency camel-jackson \
    --dependency mvn:org.codehaus.groovy/groovy-json/2.5.5 \
    --trait service.auto=false \
    --trait service.port=8080 \
    --trait gc.enabled=false \
    damage-service.groovy
*/
import org.infinispan.client.hotrod.configuration.ConfigurationBuilder
import org.infinispan.client.hotrod.configuration.SaslQop
import org.infinispan.client.hotrod.RemoteCache
import org.infinispan.client.hotrod.RemoteCacheManager
import org.infinispan.client.hotrod.RemoteCounterManagerFactory
import org.infinispan.client.hotrod.configuration.Configuration
import org.infinispan.counter.api.CounterConfiguration
import org.infinispan.counter.api.CounterManager
import org.infinispan.counter.api.CounterType
import org.infinispan.counter.api.StrongCounter

import org.apache.camel.model.dataformat.JsonLibrary
import org.apache.camel.Processor

// *********************************************
//
// ISPN
//
// *********************************************

def config =  new ConfigurationBuilder()
    .addServer()
    .host('datagrid-service.datagrid-demo.svc.cluster.local')
    .port(11222)
    .security().authentication()
    .enable()
    .username('admin')
    .password('admin')
    .realm('ApplicationRealm')
    .serverName('datagrid-service')
    .saslMechanism('DIGEST-MD5')
    .saslQop(SaslQop.AUTH)
    .build()

def cacheMgr   = new RemoteCacheManager(config)
def counterMgr = RemoteCounterManagerFactory.asCounterManager(cacheMgr)
def counterCfg = CounterConfiguration.builder(CounterType.BOUNDED_STRONG).initialValue(100).lowerBound(0).build()

// *********************************************
//
// Functions
//
// *********************************************

def applyDamage = {
    long transposedDamage = it.in.body.damage * 1_000_000_000_000_000_000

    counter = counterMgr.getStrongCounter("machine-${it.in.body.machineId}")
    counter.addAndGet(-transposedDamage);
} as Processor

def sensorToDamage = {
    it.in.body = groovy.json.JsonOutput.toJson([
        'machineId': it.in.body.machineId,
        'damage': java.util.concurrent.ThreadLocalRandom.current().nextInt(0, 100)
    ])
} as Processor 

// *********************************************
//
// Rest
//
// *********************************************

rest {
    configuration {
        port '8080'
        component 'netty4-http'
    }

    path('/ApplyDamage') {
        post()
            .consumes('application/json')
            .produces('application/json')
            .route()
                .unmarshal().json(JsonLibrary.Jackson, Map.class)
                .process(applyDamage)
                .to('log:applyDamage')
    }

    path('/SensorToDamage') {
        post()
            .consumes('application/json')
            .produces('application/json')
            .route()
                .unmarshal().json(JsonLibrary.Jackson, Map.class)
                .process(sensorToDamage)
                .to('log:sensorToDamage')
    }
}