/*
./kamel run \
    --name damage-service-test \
    --profile openshift \
    --dependency camel-netty4-http \
    --trait service.auto=false \
    --trait service.port=8080 \
    --trait gc.enabled=false \
    damage-service-test.groovy
*/

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
                .log("aply delay")
                .process { 
                    Thread.sleep(
                        java.util.concurrent.ThreadLocalRandom.current().nextInt(500, 1000)
                    ) 
                }
                .log("delayed...")
                .setBody().constant('delayed')
    }
}
