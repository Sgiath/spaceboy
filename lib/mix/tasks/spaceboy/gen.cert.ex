defmodule Mix.Tasks.Spaceboy.Gen.Cert do
  @shortdoc "Generates self-signed certificate"

  @moduledoc ~S"""
  Generates self-signed certificate for localhost and saves it at `priv/ssl/`

  By default uses EC `prime256v1` as it is the most widely supported EC algorithm.
  But once support for `ED25519` curve will grow I will switch it to this one
  for security reasons and to promote good practices. If you want to use ED25519
  even now you can use `--ed25519` option in this task.

  When first used it copies default `openssl.cnf` to your `priv/ssl/` directory
  and generates self-sgined certificate for `localhost` and `127.0.0.1`. If you
  want certificate for different hosts and IPs you can edit the generated
  `priv/ssl/openssl.cnf` file manually, generate new certificate and it will use
  those values instead.

  ## Options

  You can specify how many days certificate should be valid. Default is 365 days
  but you can specify different one (e.g. 100 years):

      mix spaceboy.gen.cert --days 36500

  You can specify to generate private key with ED25519 algorithm:

      mix spaceboy.gen.cert --ed25519

  ## Dependencies

  This mix task is calling `openssl` program so you need to have it installed and
  in path.
  """

  use Mix.Task

  @root_path "priv/ssl"
  @key_path "#{@root_path}/key.pem"
  @cert_path "#{@root_path}/cert.pem"
  @cnf_path "#{@root_path}/openssl.cnf"
  @cnf_default Application.app_dir(:spaceboy, "priv/openssl.cnf")

  @ec [
    "-algorithm=ec",
    "-pkeyopt=ec_paramgen_curve:prime256v1"
  ]
  @ed25519 [
    "-algorithm=ed25519"
  ]

  @switches [days: :integer, ed25519: :boolean]
  @aliases [d: :days]

  @doc false
  @impl Mix.Task
  def run(args) do
    {opts, _parsed} = OptionParser.parse!(args, strict: @switches, aliases: @aliases)

    copy_cnf()
    gen_pkey(opts)
    gen_cert(opts)
  end

  # Copy default cnf file if it doesn't exists
  defp copy_cnf do
    File.mkdir_p(@root_path)

    unless File.exists?(@cnf_path) do
      File.cp(@cnf_default, @cnf_path)

      IO.puts("""
      \n#{IO.ANSI.yellow()}#{IO.ANSI.bright()}# OpenSSL Config#{IO.ANSI.reset()}
      Created default openssl config file at #{path(@cnf_path)}
      It won't be overwriten so you can edit it and it will be used on subsequent cert
      generations.
      """)
    end
  end

  # Generate private key
  defp gen_pkey(opts) do
    IO.puts("\n#{IO.ANSI.yellow()}#{IO.ANSI.bright()}# Private Key#{IO.ANSI.reset()}")

    if File.exists?(@key_path) do
      IO.puts("""
      Found private key at #{path(@key_path)}
      Using existing key instead of generating new one.
      """)
    else
      algo = if Keyword.get(opts, :ed25519, false), do: @ed25519, else: @ec

      System.cmd(
        "openssl",
        [
          "genpkey",
          "-out=#{@key_path}"
        ] ++ algo
      )

      IO.puts("""
      Generated new private key at #{path(@key_path)}
      """)
    end
  end

  # Generate and self-sign certificate
  defp gen_cert(opts) do
    System.cmd("openssl", [
      "req",
      "-new",
      "-x509",
      "-days=#{Keyword.get(opts, :days, 365)}",
      "-key=#{@key_path}",
      "-out=#{@cert_path}",
      "-config=#{@cnf_path}"
    ])

    IO.puts("""
    \n#{IO.ANSI.yellow()}#{IO.ANSI.bright()}# TLS Certificate#{IO.ANSI.reset()}
    Generated self-signed certificate at #{path(@cert_path)}
    You can inspect your certificate with this command:

        #{IO.ANSI.bright()}openssl x509 -in #{@cert_path} -text -noout#{IO.ANSI.reset()}
    """)
  end

  defp path(text) do
    "#{IO.ANSI.light_black()}#{IO.ANSI.italic()}#{text}#{IO.ANSI.reset()}"
  end
end
