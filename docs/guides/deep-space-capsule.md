# Deep Space Capsule

Deep Space Capsule refers to Gemini page which is running only as Tor service.
The setup is pretty straightforward but there are some non-obvious steps you
need to do. In next steps we will assume you have your server written and `tor`
is installed on your hosting machine. So here is the process:

* Add Tor configuration for the capsule in `/etc/tor/torrc` config:

    ```torrc
    HiddenServiceDir /var/lib/tor/gemini/
    HiddenServicePort 1965 127.0.0.1:1965
    ```

* Restart Tor (this will initialize the onion service)
* Get the .onion address

    ```bash
    cat /var/lib/tor/gemini/hostname
    ```

* Add your .onion hostname to your self-signed certificate. If you are using
  build-in command `mix spaceboy.gen.cert` you can do it by edditing
  `priv/ssl/openssl.cnf` - change this lines:

    ```cnf
    [alt_names]
    IP.1 = 127.0.0.1
    DNS.1 = localhost
    ```

  to this ones:

    ```cnf
    [alt_names]
    DNS.1 = <your-onion-address-here>.onion
    ```

  and regenerate the certificate `mix spaceboy.gen.cert`.

* Prepare your configuration. You need to do two things - bind your server to
  IP address `127.0.0.1` instead of `0.0.0.0` (default) and add your .onion
  address to `:allowed_hosts`:

    ```elixir
    config :example, Example.Server,
      bind: "127.0.0.1",
      allowed_hosts: ["<your-onion-address-here>.onion"]
    ```

  **_Note:_ this step is currently not supported!**

* Now you can start your server and access it through Tor network!

_Note:_ all credit goes to this guy who I blatantly copied
<gemini://gemini.bortzmeyer.org/gemini/onion.gmi>
