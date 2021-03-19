defmodule Example.Controller do
  alias Spaceboy.Conn

  require Logger

  @doc """
  Index page with Gemini response constructed as string
  """
  def index(conn) do
    Conn.gemini(conn, """
    # Example page

    This is index page

    => /user Set username
    => /cert Check certificate
    => /file File test
    => /static Folder test
    => /static/projects Folder without index.gmi

    Server time: #{DateTime.utc_now()}
    """)
  end

  @doc """
  Page requiring user input and then redirecting to appropriate page
  """
  def users(%Conn{query_string: nil} = conn) do
    Conn.input(conn, "Enter username")
  end

  def users(%Conn{query_string: user} = conn) do
    Logger.info("Processing user: #{user}")

    Conn.redirect(conn, "/user/#{user}")
  end

  @doc """
  Page with URL parameter
  """
  def user(%Conn{params: %{user_id: user_id}} = conn) do
    Conn.gemini(conn, """
    # Example user page

    => / Home

    ## User
    ```
    User ID: "#{user_id}"
    ```
    """)
  end

  @doc """
  Page showing work with certificates
  """
  def cert(%Conn{peer_cert: :no_peercert} = conn) do
    Conn.auth_required(conn)
  end

  def cert(%Conn{peer_cert: pc} = conn) do
    data = Spaceboy.PeerCert.rdn(pc)

    Conn.gemini(conn, """
    # Example certificate page

    Great! Certificate detected:

    ```
    #{inspect(data)}
    ```
    """)
  end

  @doc """
  Serving single file as a response
  """
  def file(conn) do
    Conn.file(conn, "priv/test.txt")
  end
end
