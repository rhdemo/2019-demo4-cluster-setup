var StringClass = Java.type('java.lang.String');

from('netty4-http:0.0.0.0:8080')
    .convertBodyTo(StringClass)
    .to('log:info?multiline=true')
