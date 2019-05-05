import org.apache.camel.AsyncCallback
import org.apache.camel.AsyncProcessor
import org.apache.camel.Exchange
import org.apache.camel.Processor
import org.apache.camel.Route
import org.apache.camel.model.dataformat.JsonLibrary
import org.apache.camel.support.RoutePolicySupport
import org.apache.camel.util.AsyncProcessorHelper

logger = org.slf4j.LoggerFactory.getLogger("damage-game")

from('timer:inject?period={{timer.period:1s}}')
    .process {
        long counter   = it.properties.get(org.apache.camel.Exchange.TIMER_COUNTER, long.class)
        long machineId = counter % 10

        it.message.body = """{ \"machineId\": ${machineId}, \"vibrationClass\": \"shake\" } """ as String
    }
    .to('seda:send?waitForTaskToComplete=Never')
from('seda:send?concurrentConsumers={{seda.consumers:25}}')
    .routePolicy(new RoutePolicySupport() {
              @Override
              public void onExchangeDone(Route route, Exchange exchange) {
                logger.info('exchange duration={}, failed={}, data={}',
                    System.currentTimeMillis() - exchange.created.time,
                    exchange.exception != null,
                    exchange.message.getBody(String.class)
                )
              }
          })
    .to("http4:damage-game.syndesis.svc.cluster.local")
