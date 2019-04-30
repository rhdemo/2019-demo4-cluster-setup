from('timer:inject?period={{timer.period:100}}')
    .process {
        long counter   = it.properties.get(org.apache.camel.Exchange.TIMER_COUNTER, long.class)
        long machineId = counter % 10

        it.message.body = """{ \"machineId\": ${machineId}, \"vibrationClass\": \"floss\" } """ as String
    }
    .to('seda:send?waitForTaskToComplete=Never')
from('seda:send?concurrentConsumers={{seda.consumers:25}}')
    .to('log:data')
    .to('http4://damage-service/ApplyDamage')
