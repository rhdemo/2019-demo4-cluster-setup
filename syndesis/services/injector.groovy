event = '''{
    "sensorId": "360a3255-7b14-45b8-9624-8ee396a716c8",
    "machineId": 3,
    "vibrationClass": "floss",
    "confidencePercentage": 80
}'''

from("timer:clock?delay=2s&period=5s&repeatCount=5")
    .setBody().constant(event)
    .to("knative:endpoint/i-sensorstream-dumper")