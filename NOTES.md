Notes for k8s integration
==

# Log shipping

Logs should be handled as follows:
 * php application logs directly to php://stdout
 * php fpm must be configured to catch script output and redirecting it to stderr (stdout not working) (`/proc/self/fd/2`)
 * docker catches fpm stdout/stderr and logs it into json by default
 * fluent bit is installed as a DaemonSet and ships logs for node containers to elastic search
 
There's a quirk for fpm output, because application logs (access logs are fine) are wrapped in a string like:
```
[17-Jul-2017 09:31:09] WARNING: [pool www] child 22 said into stderr: "{"foo":"Foo","bar":"Baz"}"
```
resulting in docker logs:
```
{
    "log":"[17-Jul-2017 09:31:09] WARNING: [pool www] child 22 said into stderr: \"{\"foo\":\"Foo\",\"bar\":\"Baz\"}\"\r\n",
    "stream":"stdout",
    "time":"2017-07-17T09:31:09.949290842Z"
}
```

With fluent-bit 0.12-DEV we can improve the situation without too much impact at app level
```
# parsers.conf
[PARSER]
    Name fpm
    Format regex
    Regex ^\[(?<time>.*)\] WARNING: \[pool (?<pool>[a-z]*)\] child (?<pid>.*) said into (?<stream>.*): \\"(?<log>.*)\\"\\r\\n$
    Time_Key time
    Time_Format %d-%b-%Y %H:%M:%S
```

```
# fluent-bit.conf
[INPUT]
    Name           tail
    Tag            kube.*
    Path           /var/log/containers/*.log
    Parser         docker
    DB             /var/log/flb_kube.db
    Mem_Buf_Limit  5MB
    
[FILTER]
    Name parser
    Parser fpm
    Match kube.*
    Key_Name log
    
[FILTER]
    Name           kubernetes
    Match          kube.*
    Kube_URL       https://kubernetes.default.svc:443
    Merge_JSON_Log On
```
