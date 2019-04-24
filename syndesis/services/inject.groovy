from("timer:clock?period=100")
    .setBody().constant('{ "message": "raw" }')
    .to("seda:queue?waitForTaskToComplete=Never")

from("seda:queue?concurrentConsumers=20")
    .log('Sending: ${body}')
    .to("knative:endpoint/sensor-to-damage")

