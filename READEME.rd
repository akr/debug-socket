= debug-socket

debug-socket dumps TCP socket communication for debugging.

== Author

Tanaka Akira <akr@m17n.org>

== License

Ruby's.

== Usage

  % ruby -rdebug-socket ...

Just require it.

The communication via TCP socket is stored to /tmp/debug-socket-*.

== Example

The usage is just require it as follows.

  % ruby -rdebug-socket -ropen-uri -e 'URI("http://www.ruby-lang.org/").read'

The communication is stored into /tmp/debug-socket-*.

  % ls -l /tmp/debug-socket-*
  -rw-r--r--  1 akr akr   572 2006-02-07 17:05 /tmp/debug-socket-1
  -rw-r--r--  1 akr akr 22697 2006-02-07 17:05 /tmp/debug-socket-2

In this case, the program uses 2 socket communcations.

The first is follows.

  % cat /tmp/debug-socket-1 
  www.ruby-lang.org:80
  0>"GET / HTTP/1.1\r\n"
  16>"Accept: */*\r\n"
  29>"Host: www.ruby-lang.org\r\n"
  54>"\r\n"
  0<"HTTP/1.1 302 Found\r\n"
  20<"Date: Tue, 07 Feb 2006 08:06:31 GMT\r\n"
  57<"Server: Apache/2.0.54 (Debian GNU/Linux) mod_ruby/1.2.4 Ruby/1.8.2(2005-04-11) mod_ssl/2.0.54 OpenSSL/0.9.7e\r\n"
  167<"Location: http://www.ruby-lang.org/en/\r\n"
  207<"Vary: Accept-Language\r\n"
  230<"Transfer-Encoding: chunked\r\n"
  258<"Content-Type: text/html; charset=iso-8859-1\r\n"
  303<"\r\n"
  305<"2c\r\n"
  309<"<html><body><h1>302 Found</h1></body></html>\r\n"
  355<"0\r\n"
  358<"\r\n"

The first line, "www.ruby-lang.org:80", means destination.

The numbers at beginneng of line means byte count since start of the communication.
">" means client-to-server data.
"<" means server-to-client data.

