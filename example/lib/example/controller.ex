defmodule Example.Controller do
  use Spaceboy.Controller,
    root: "lib/example/templates"

  alias Spaceboy.Conn
  alias Spaceboy.PeerCert

  require Logger

  @doc ~S"""
  Index page with Gemini response constructed as string
  """
  def index(conn) do
    gemini(conn, """
    # Example page

    This is index page

    => /user Set username
    => /cert Check certificate
    => /file File test
    => /template Template test
    => /static Folder test
    => /static/projects Folder without index.gmi

    Server time: #{DateTime.utc_now()}
    """)
  end

  @doc ~S"""
  Page requiring user input and then redirecting to appropriate page
  """
  def users(%Conn{query_string: nil} = conn) do
    input(conn, "Enter username")
  end

  def users(%Conn{query_string: user} = conn) do
    Logger.info("Processing user: #{user}")

    redirect(conn, "/user/#{user}")
  end

  @doc ~S"""
  Page with URL parameter
  """
  def user(%Conn{params: %{user_id: user_id}} = conn) do
    gemini(conn, """
    # Example user page

    => / Home

    ## User
    ```
    User ID: "#{user_id}"
    ```
    """)
  end

  @doc ~S"""
  Page showing work with certificates
  """
  def cert(%Conn{peer_cert: :no_peercert} = conn) do
    auth_required(conn)
  end

  def cert(%Conn{peer_cert: pc} = conn) do
    data = PeerCert.rdn(pc)

    gemini(conn, """
    # Example certificate page

    Great! Certificate detected:

    ```
    #{inspect(data)}
    ```

    ## Fingerprint
    #{PeerCert.fingerprint(pc)}
    """)
  end

  @doc ~S"""
  Rendering and serving a template in the template root (`templates/`)
  """
  def template(conn) do
    render(conn, "test.gmi", num: :rand.uniform(10))
  end

  @doc ~S"""
  Serving single file as a response
  """
  def file(conn) do
    Conn.file(conn, "priv/test.txt")
  end
end
