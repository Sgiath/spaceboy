defmodule Mix.Tasks.Spaceboy.Gen.Cert do
  @shortdoc "Generates self-signed certificate"

  @moduledoc ~S"""
  Generates self-signed certificate for localhost and saves it at `priv/ssl/`

  Currently uses EC `prime256v1` as it is the most widely supported EC algorithm.
  But once Erlang adds support for `ED25519` curve I will switch it to this one
  for security reasons and to promote good practices.

  https://github.com/erlang/otp/issues/4637

  When first used it copies default `openssl.cnf` to your `priv/ssl/` directory
  and generates self-sgined certificate for `localhost` and `127.0.0.1`. If you
  want certificate for different hosts and IPs you can edit the generated
  `priv/ssl/openssl.cnf` file manually, generate new certificate and it will use
  those values instead.

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

  @doc false
  def run(_args) do
    copy_cnf()
    gen_pkey()
    gen_cert()

    IO.puts("""
    \n#{IO.ANSI.yellow()}#{IO.ANSI.bright()}# TLS Certificate#{IO.ANSI.reset()}
    Generated private key and self-signed certificate:

      - #{@key_path}
      - #{@cert_path}
    """)
  end

  # Copy default cnf file if it doesn't exists
  defp copy_cnf do
    File.mkdir_p(@root_path)

    unless File.exists?(@cnf_path) do
      File.cp(@cnf_default, @cnf_path)

      IO.puts("""
      \n#{IO.ANSI.yellow()}#{IO.ANSI.bright()}# OpenSSL Config#{IO.ANSI.reset()}
      Created default openssl config file at "#{@cnf_path}".
      It won't be overwriten so you can edit it will be used on subsequent cert generations.
      """)
    end
  end

  # Generate private key
  defp gen_pkey do
    System.cmd("openssl", [
      "genpkey",
      "-algorithm=EC",
      "-pkeyopt=ec_paramgen_curve:prime256v1",
      "-pkeyopt=ec_param_enc:named_curve",
      "-out=#{@key_path}"
    ])
  end

  # Generate and self-sign certificate
  defp gen_cert do
    System.cmd("openssl", [
      "req",
      "-new",
      "-x509",
      "-days=1825",
      "-key=#{@key_path}",
      "-out=#{@cert_path}",
      "-config=#{@cnf_path}"
    ])
  end
end
