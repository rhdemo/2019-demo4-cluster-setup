/*
kamel run \
    --name damage-service \
    --profile openshift \
    --dependency camel-netty4-http \
    --dependency camel-jackson \
    --dependency mvn:org.infinispan/infinispan-client-hotrod/9.4.12.Final \
    --dependency mvn:org.infinispan/infinispan-query-dsl/9.4.12.Final \
    --dependency mvn:org.infinispan/infinispan-commons/9.4.12.Final \
    --dependency mvn:org.codehaus.groovy/groovy-json/2.5.5 \
    --trait service.auto=false \
    --trait service.port=8080 \
    --trait gc.enabled=false \
    --dev \
    services/damage-service.groovy
*/

import java.nio.charset.StandardCharsets
import org.infinispan.commons.marshall.StringMarshaller
import org.infinispan.client.hotrod.configuration.NearCacheMode
import org.infinispan.client.hotrod.configuration.ClientIntelligence
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

def logger     = org.slf4j.LoggerFactory.getLogger("damage-service")
def mapper     = new com.fasterxml.jackson.databind.ObjectMapper()
def cacheHost  = 'datagrid-service.datagrid-demo.svc.cluster.local'
def cachePort  = 11222

def cacheCfg   = new ConfigurationBuilder()
    .addServer().host(cacheHost).port(cachePort)
    .marshaller(new StringMarshaller(StandardCharsets.UTF_8))
    .clientIntelligence(ClientIntelligence.BASIC)
    .build()

def cacheMgr   = new RemoteCacheManager(cacheCfg)
def counterMgr = RemoteCounterManagerFactory.asCounterManager(cacheMgr)
def cache      = cacheMgr.getCache()

def applyDamage = {
    def kind    = it.in.body.vibrationClass
    def cname   = "machine-${it.in.body.machineId}"
    def gamecfg = cache['game']

    if (gamecfg != null && kind != null) {
        def config = mapper.readValue(gamecfg, Map.class)
        def countr = counterMgr.getStrongCounter(cname)
        
        double damage  = config.damage."${kind}"
        double multipl = config.damageMultiplier
        long   tdamage = damage * multipl * 1_000_000_000_000_000_000

        logger.info("${cname}  ${config} ${kind} ${damage} ${multipl} ${tdamage}")
        
        countr.getValue().thenAccept({
            value -> logger.info('machine-{} old value: {}', it.in.body.machineId, value)
        }).get()
        countr.addAndGet(-tdamage).thenAccept({
            value -> logger.info('machine-{} new value: {}', it.in.body.machineId, value)
        }).get()
    }
    
    if (gamecfg == null) { 
        logger.warn("No game config found")
    }
    if (kind == null) { 
        logger.warn("No kind found")
    }
}

rest {
    configuration {
        port '8080'
        component 'netty4-http'
    }

    path('/ApplyDamage') {
        post()
            .consumes('application/json')
            .produces('application/json')
            .to('seda:applyDamage')
    }
}

from('seda:applyDamage?concurrentConsumers=25')
    .unmarshal().json(JsonLibrary.Jackson, Map.class)
    .process(applyDamage as Processor)
    .to('log:applyDamage')
