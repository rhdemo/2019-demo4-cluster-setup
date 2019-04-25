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

import org.apache.camel.AsyncCallback
import org.apache.camel.AsyncProcessor
import org.apache.camel.Exchange
import org.apache.camel.model.dataformat.JsonLibrary
import org.apache.camel.util.AsyncProcessorHelper
import org.infinispan.client.hotrod.RemoteCacheManager
import org.infinispan.client.hotrod.RemoteCounterManagerFactory
import org.infinispan.client.hotrod.configuration.ClientIntelligence
import org.infinispan.client.hotrod.configuration.ConfigurationBuilder
import org.infinispan.commons.marshall.StringMarshaller
import org.infinispan.counter.exception.CounterOutOfBoundsException
import java.nio.charset.StandardCharsets

def logger     = org.slf4j.LoggerFactory.getLogger("damage-service")
def mapper     = new com.fasterxml.jackson.databind.ObjectMapper()
def cacheHost  = 'datagrid-service.datagrid-demo.svc.cluster.local'
def cachePort  = 11222
def cacheCfg   = new ConfigurationBuilder()
        .addServer().host(cacheHost).port(cachePort)
        .marshaller(new StringMarshaller(StandardCharsets.UTF_8))
        .clientIntelligence(ClientIntelligence.BASIC)
        .nearCache().maxEntries(100)
        .build()

def cacheMgr   = new RemoteCacheManager(cacheCfg)
def counterMgr = RemoteCounterManagerFactory.asCounterManager(cacheMgr)
def cache      = cacheMgr.getCache('game')

def applyDamage = new AsyncProcessor() {
    @Override
    boolean process(Exchange exchange, AsyncCallback callback) {
        String kind    = exchange.message.body.vibrationClass
        String cname   = "machine-${exchange.message.body.machineId}"
        String gamecfg = cache['game']

        if (gamecfg != null && kind != null) {
            def config = mapper.readValue(gamecfg, Map.class)
            def scount = counterMgr.getStrongCounter(cname)

            Double damage  = config.damage."${kind}"
            Double multipl = config.damageMultiplier

            if (damage == null) {
                logger.warn("No damage defined for ${kind}")
                return
            }
            if (multipl == null) {
                logger.warn("No damage multiplier defined for ${kind}")
                return
            }

            long tdamage = damage.doubleValue() * multipl.doubleValue() * 1_000_000_000_000_000_000

            scount.addAndGet(-tdamage).handleAsync { v, e ->
                exchange.message.body.damage = damage
                exchange.message.body.damageMultiplier = multipl
                exchange.message.body.damageApplied = tdamage
                exchange.message.body.counter = v
                exchange.exception = e

                if (e instanceof CounterOutOfBoundsException) {
                    exchange.exception = null
                    exchange.message.body.note = e.getMessage()
                }

                callback.done(false)
            }
        }

        if (gamecfg == null) {
            logger.warn("No game config found")
        }
        if (kind == null) {
            logger.warn("No kind found")
        }

        return false
    }

    @Override
    void process(Exchange exchange) throws Exception {
        AsyncProcessorHelper.process(this, exchange)
    }
}

from('netty4-http:0.0.0.0:8080/ApplyDamage')
    .to('seda:applyDamage')

from('seda:applyDamage?concurrentConsumers=25')
    .unmarshal().json(JsonLibrary.Jackson, Map.class)
    .log('req: ${body}')
    .process(applyDamage)
    .log('res: ${body}')
