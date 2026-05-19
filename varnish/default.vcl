vcl 4.0;

import std;

# Definir backend con resolución de DNS retry
backend default {
    .host = "web";
    .port = "80";
    .probe = {
        .url = "/";
        .timeout = 1s;
        .interval = 5s;
        .window = 5;
        .threshold = 3;
    }
    .resolve = "docker";
}

sub vcl_recv {
    if (req.method == "PURGE") {
        return (purge);
    }
    
    if (req.url ~ "^/(pub/)?(media|static)/") {
        return (pass);
    }
}

sub vcl_backend_response {
    set beresp.ttl = 1d;
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
} 
