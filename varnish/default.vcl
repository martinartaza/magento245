vcl 4.1;

import std;

backend default {
    .host = "web";
    .port = "80";
    .first_byte_timeout = 300s;
    .connect_timeout = 5s;
    .between_bytes_timeout = 2s;
}

sub vcl_recv {
    if (req.method == "PURGE") {
        return (purge);
    }
    if (req.url ~ "^/admin" || req.url ~ "^/(pub/)?(media|static)/") {
        return (pass);
    }
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }
}

sub vcl_backend_response {
    set beresp.ttl = 1d;
    set beresp.grace = 1h;
    if (beresp.http.Set-Cookie) {
        set beresp.ttl = 0s;
    }
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
}
