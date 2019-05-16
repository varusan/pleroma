# Installing on OpenBSD
## Installation

This guide is a step-by-step installation guide for OpenBSD.
Commands starting with `#` should be launched as root, with `$` they should be launched as the `pleroma` user, with `%` they can be launched with any user on the machine, in case they need a specific user they’ll be prefixed with `username $`. It is recommended to keep the session until it changes of user or tells you to exit. See [[unix session management]] if you do not know how to do it.

### Required packages
The following packages need to be installed:
* `elixir`
* `git`
* `gmake`
* `ImageMagick`
* `postgresql-contrib`
* `postgresql-server`

To install them run the following command:
```shell
# pkg_add elixir git gmake ImageMagick postgresql-contrib postgresql-server
```

Pleroma requires a reverse proxy, OpenBSD has relayd in base (and is used in this guide), ports are available for nginx (`www/nginx`) and apache (`www/apache-httpd`). Independently of the reverse proxy, [acme-client(1)](https://man.openbsd.org/acme-client) can be used to get a certificate from Let's Encrypt.

### Prepare the system
Pleroma will be run by a dedicated user, `pleroma`. Before creating it, insert the following lines in `login.conf`:
```plain
pleroma:\
	:datasize-max=1536M:\
	:datasize-cur=1536M:\
	:openfiles-max=4096
```
This creates a "pleroma" login class and sets higher values than default for datasize and openfiles (see [login.conf(5)](https://man.openbsd.org/login.conf)), this is required to avoid having pleroma crash some time after starting.

* Add a new system user for the Pleroma service:
```shell
# useradd -d /opt/pleroma -s /bin/false -m -L pleroma pleroma
```

### Install PostgreSQL

* Initialize database:

```shell
_postgresql $ initdb
```

* Enable and start postgresql server:
```shell
# rcctl enable postgresql
# rcctl start postgresql
```
To check that it started properly and didn't fail right after starting, you can run `ps aux | grep postgres`, there should be multiple lines of output.

#### Install httpd
httpd will have three fuctions:
* redirect requests trying to reach the instance over http to the https URL
* get Let's Encrypt certificates, with acme-client

Insert the following config in `httpd.conf`:
```plain
# $OpenBSD: httpd.conf,v 1.17 2017/04/16 08:50:49 ajacoutot Exp $

ext_inet="<IPv4 address>"
ext_inet6="<IPv6 address>"

server "default" {
	listen on $ext_inet port 80 # Comment to disable listening on IPv4
	listen on $ext_inet6 port 80 # Comment to disable listening on IPv6
	listen on 127.0.0.1 port 80 # Do NOT comment this line

	log syslog
	directory no index

	location "/.well-known/acme-challenge/*" {
		root "/acme"
		request strip 2
	}

	location "/*" { block return 302 "https://$HTTP_HOST$REQUEST_URI" }
}

types {
	include "/usr/share/misc/mime.types"
}
```
Do not forget to change `<IPv4/6 address>` to your server's addresses. If httpd should only listen on one protocol family, comment one of the two first `listen` options.

Check the configuration with `httpd -n`, if it is OK enable and start httpd (as root):
```shell
# rcctl enable httpd
# rcctl start httpd
```

#### acme-client
acme-client is used to get SSL/TLS certificates from Let's Encrypt. 
Insert the following configuration in `/etc/acme-client.conf`:
```plain
#
# $OpenBSD: acme-client.conf,v 1.4 2017/03/22 11:14:14 benno Exp $
#

authority letsencrypt-<domain name> {
	#agreement url "https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf"
	api url "https://acme-v01.api.letsencrypt.org/directory"
	account key "/etc/acme/letsencrypt-privkey-<domain name>.pem"
}

domain <domain name> {
	domain key "/etc/ssl/private/<domain name>.key"
	domain certificate "/etc/ssl/<domain name>.crt"
	domain full chain certificate "/etc/ssl/<domain name>.fullchain.pem"
	sign with letsencrypt-<domain name>
	challengedir "/var/www/acme/"
}
```
Replace *\<domain name\>* by the domain name you'll use for your instance. As root, run `acme-client -n` to check the config, then `acme-client -ADv <domain name>` to create account and domain keys, and request a certificate for the first time.  
Make acme-client run everyday by adding it in /etc/daily.local. As root, run the following command: `echo "acme-client <domain name>" >> /etc/daily.local`.

Relayd will look for certificates and keys based on the address it listens on (see relayd section), the easiest way to make them available to relayd is to create a link:
```shell
# ln -s /etc/ssl/<domain name>.fullchain.pem /etc/ssl/<IP address>.crt
# ln -s /etc/ssl/private/<domain name>.key /etc/ssl/private/<IP address>.key
```
This will have to be done for each IPv4 and IPv6 address relayd listens on.

#### relayd
relayd will be used as the reverse proxy sitting in front of pleroma. 
Insert the following configuration in `/etc/relayd.conf`:
```
# $OpenBSD: relayd.conf,v 1.4 2018/03/23 09:55:06 claudio Exp $

ext_inet="<IPv4 address>"
ext_inet6="<IPv6 address>"

table <pleroma_server> { 127.0.0.1 }
table <httpd_server> { 127.0.0.1 }

http protocol plerup { # Protocol for upstream pleroma server
	#tcp { nodelay, sack, socket buffer 65536, backlog 128 } # Uncomment and adjust as you see fit
	tls ciphers "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305"
	tls ecdhe secp384r1

	# Append a bunch of headers
	match request header append "X-Forwarded-For" value "$REMOTE_ADDR" # This two header and the next one are not strictly required by pleroma but adding them won't hurt
	match request header append "X-Forwarded-By" value "$SERVER_ADDR:$SERVER_PORT"

	match response header append "X-XSS-Protection" value "1; mode=block"
	match response header append "X-Permitted-Cross-Domain-Policies" value "none"
	match response header append "X-Frame-Options" value "DENY"
	match response header append "X-Content-Type-Options" value "nosniff"
	match response header append "Referrer-Policy" value "same-origin"
	match response header append "X-Download-Options" value "noopen"
	match response header append "Content-Security-Policy" value "default-src 'none'; base-uri 'self'; form-action 'self'; img-src 'self' data: https:; media-src 'self' https:; style-src 'self' 'unsafe-inline'; font-src 'self'; script-src 'self'; connect-src 'self' wss://CHANGEME.tld; upgrade-insecure-requests;" # Modify "CHANGEME.tld" and set your instance's domain here
	match request header append "Connection" value "upgrade"
	#match response header append "Strict-Transport-Security" value "max-age=31536000; includeSubDomains" # Uncomment this only after you get HTTPS working.

	# If you do not want remote frontends to be able to access your Pleroma backend server, comment these lines
	match response header append "Access-Control-Allow-Origin" value "*"
	match response header append "Access-Control-Allow-Methods" value "POST, PUT, DELETE, GET, PATCH, OPTIONS"
	match response header append "Access-Control-Allow-Headers" value "Authorization, Content-Type, Idempotency-Key"
	match response header append "Access-Control-Expose-Headers" value "Link, X-RateLimit-Reset, X-RateLimit-Limit, X-RateLimit-Remaining, X-Request-Id"
	# Stop commenting lines here
}

relay wwwtls {
	listen on $ext_inet port https tls # Comment to disable listening on IPv4
	listen on $ext_inet6 port https tls # Comment to disable listening on IPv6

	protocol plerup

	forward to <pleroma_server> port 4000 check http "/" code 200
}
```
Again, change *\<IPv4/6 address\>* to your server's address(es) and comment one of the two *listen* options if needed. Also change *wss://CHANGEME.tld* to *wss://\<your instance's domain name\>*.  
Check the configuration with `relayd -n`, if it is OK enable and start relayd (as root):
```shell
# rcctl enable relayd
# rcctl start relayd
```

#### pf
Enabling and configuring pf is highly recommended.  
In /etc/pf.conf, insert the following configuration:
```
# Macros
if="<network interface>"
authorized_ssh_clients="any"

# Skip traffic on loopback interface
set skip on lo

# Default behavior
set block-policy drop
block in log all
pass out quick

# Security features
match in all scrub (no-df random-id)
block in log from urpf-failed

# Rules
pass in quick on $if inet proto icmp to ($if) icmp-type { echoreq unreach paramprob trace } # ICMP
pass in quick on $if inet6 proto icmp6 to ($if) icmp6-type { echoreq unreach paramprob timex toobig } # ICMPv6
pass in quick on $if proto tcp to ($if) port { http https } # relayd/httpd
pass in quick on $if proto tcp from $authorized_ssh_clients to ($if) port ssh
```
Replace `<network interface>` by your server's network interface name (which you can get with ifconfig). Consider replacing the content of the authorized\_ssh\_clients macro by, for exemple, your home IP address, to avoid SSH connection attempts from bots.

Check pf's configuration by running `pfctl -nf /etc/pf.conf`, load it with `pfctl -f /etc/pf.conf` and enable pf at boot with `rcctl enable pf`.

### Install and Configure Pleroma
You can now follow [Generic Pleroma Installation](generic_pleroma_en.html).
