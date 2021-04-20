defmodule SpaceboyTest.Header do
  use ExUnit.Case

  alias Spaceboy.Header

  doctest Spaceboy.Header

  describe "format" do
    test "with meta" do
      header = Header.format(%Header{code: 20, meta: "test"})

      assert header == "20 test\r\n"
    end

    test "without meta" do
      header = Header.format(%Header{code: 40})

      assert header == "40\r\n"
    end
  end

  describe "official headers" do
    setup do
      {:ok, %{prompt: "Test prompt"}}
    end

    test "input", %{prompt: prompt} do
      header = Header.input(prompt)

      assert header.code == 10
      assert header.meta == prompt
    end

    test "sensitive input", %{prompt: prompt} do
      header = Header.sensitive_input(prompt)

      assert header.code == 11
      assert header.meta == prompt
    end

    test "success", %{prompt: prompt} do
      header = Header.success(prompt)

      assert header.code == 20
      assert header.meta == prompt
    end

    test "redirect", %{prompt: prompt} do
      header = Header.redirect(prompt)

      assert header.code == 30
      assert header.meta == prompt
    end

    test "temporary_redirect", %{prompt: prompt} do
      header = Header.temporary_redirect(prompt)

      assert header.code == 30
      assert header.meta == prompt
    end

    test "permanent_redirect", %{prompt: prompt} do
      header = Header.permanent_redirect(prompt)

      assert header.code == 31
      assert header.meta == prompt
    end

    test "temporary_failure", %{prompt: prompt} do
      header = Header.temporary_failure(prompt)

      assert header.code == 40
      assert header.meta == prompt
    end

    test "temporary_failure no prompt" do
      header = Header.temporary_failure()

      assert header.code == 40
      assert header.meta == nil
    end

    test "server_unavailable", %{prompt: prompt} do
      header = Header.server_unavailable(prompt)

      assert header.code == 41
      assert header.meta == prompt
    end

    test "server_unavailable no prompt" do
      header = Header.server_unavailable()

      assert header.code == 41
      assert header.meta == nil
    end

    test "cgi_error", %{prompt: prompt} do
      header = Header.cgi_error(prompt)

      assert header.code == 42
      assert header.meta == prompt
    end

    test "cgi_error no prompt" do
      header = Header.cgi_error()

      assert header.code == 42
      assert header.meta == nil
    end

    test "proxy_error", %{prompt: prompt} do
      header = Header.proxy_error(prompt)

      assert header.code == 43
      assert header.meta == prompt
    end

    test "proxy_error no prompt" do
      header = Header.proxy_error()

      assert header.code == 43
      assert header.meta == nil
    end

    test "slow_down", %{prompt: prompt} do
      header = Header.slow_down(prompt)

      assert header.code == 44
      assert header.meta == prompt
    end

    test "slow_down no prompt" do
      header = Header.slow_down()

      assert header.code == 44
      assert header.meta == nil
    end

    test "slow_down integer prompt" do
      header = Header.slow_down(20)

      assert header.code == 44
      assert header.meta == "Too many requests. Wait 20 seconds."
    end

    test "permanent_failure", %{prompt: prompt} do
      header = Header.permanent_failure(prompt)

      assert header.code == 50
      assert header.meta == prompt
    end

    test "permanent_failure no prompt" do
      header = Header.permanent_failure()

      assert header.code == 50
      assert header.meta == nil
    end

    test "not_found", %{prompt: prompt} do
      header = Header.not_found(prompt)

      assert header.code == 51
      assert header.meta == prompt
    end

    test "not_found no prompt" do
      header = Header.not_found()

      assert header.code == 51
      assert header.meta == nil
    end

    test "gone", %{prompt: prompt} do
      header = Header.gone(prompt)

      assert header.code == 52
      assert header.meta == prompt
    end

    test "gone no prompt" do
      header = Header.gone()

      assert header.code == 52
      assert header.meta == nil
    end

    test "proxy_request_refused", %{prompt: prompt} do
      header = Header.proxy_request_refused(prompt)

      assert header.code == 53
      assert header.meta == prompt
    end

    test "proxy_request_refused no prompt" do
      header = Header.proxy_request_refused()

      assert header.code == 53
      assert header.meta == nil
    end

    test "bad_request", %{prompt: prompt} do
      header = Header.bad_request(prompt)

      assert header.code == 59
      assert header.meta == prompt
    end

    test "bad_request no prompt" do
      header = Header.bad_request()

      assert header.code == 59
      assert header.meta == nil
    end

    test "client_certificate_required", %{prompt: prompt} do
      header = Header.client_certificate_required(prompt)

      assert header.code == 60
      assert header.meta == prompt
    end

    test "client_certificate_required no prompt" do
      header = Header.client_certificate_required()

      assert header.code == 60
      assert header.meta == nil
    end

    test "certificate_not_authorised", %{prompt: prompt} do
      header = Header.certificate_not_authorised(prompt)

      assert header.code == 61
      assert header.meta == prompt
    end

    test "certificate_not_authorised no prompt" do
      header = Header.certificate_not_authorised()

      assert header.code == 61
      assert header.meta == nil
    end

    test "certificate_not_valid", %{prompt: prompt} do
      header = Header.certificate_not_valid(prompt)

      assert header.code == 62
      assert header.meta == prompt
    end

    test "certificate_not_valid no prompt" do
      header = Header.certificate_not_valid()

      assert header.code == 62
      assert header.meta == nil
    end
  end
end
