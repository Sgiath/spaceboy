defmodule Spaceboy.PeerCert do
  @moduledoc ~S"""
  Utility functions to ease the work with Peer Certificates
  """
  @moduledoc authors: ["Sgiath <sgiath@pm.me"]

  require Record

  @type peer_cert :: binary() | atom()
  @type rdn :: %{
          subject: map(),
          issuer: map()
        }

  @doc ~S"""
  Get the fingerprint for the Public Key of the certificate
  """
  @spec fingerprint(cert :: peer_cert) :: binary()
  def fingerprint(cert) when is_binary(cert) do
    pk =
      cert
      |> otp_cert()
      |> tbs_cert()
      |> subject_public_key_info()
      |> public_key()

    :public_key.ssh_hostkey_fingerprint(:sha256, pk)
  end

  def fingerprint(error), do: error

  @doc ~S"""
  Extract RDN Sequences from certificate
  """
  @spec rdn(peer_cert :: peer_cert) :: rdn | :no_peercert
  def rdn(cert) when is_binary(cert) do
    tbs = cert |> otp_cert() |> tbs_cert()

    %{
      subject: tbs |> subject() |> decode_rdn_sequence(),
      issuer: tbs |> issuer() |> decode_rdn_sequence()
    }
  end

  def rdn(:no_peercert), do: :no_peercert

  # Internals

  defp otp_cert(cert) when is_binary(cert) do
    :public_key.pkix_decode_cert(cert, :otp)
  end

  defp tbs_cert(data) when Record.is_record(data, :OTPCertificate), do: elem(data, 1)

  defp issuer(data) when Record.is_record(data, :OTPTBSCertificate),
    do: elem(data, 4)

  defp subject(data) when Record.is_record(data, :OTPTBSCertificate),
    do: elem(data, 6)

  defp subject_public_key_info(data) when Record.is_record(data, :OTPTBSCertificate),
    do: elem(data, 7)

  defp ec_point(data) when Record.is_record(data, :OTPSubjectPublicKeyInfo), do: elem(data, 2)

  defp key_algo(data) when Record.is_record(data, :OTPSubjectPublicKeyInfo), do: elem(data, 1)

  defp named_curve(data) when Record.is_record(data, :PublicKeyAlgorithm), do: elem(data, 2)

  defp public_key(data) when Record.is_record(data, :OTPSubjectPublicKeyInfo) do
    {ec_point(data), data |> key_algo() |> named_curve()}
  end

  defp decode_rdn_sequence({:rdnSequence, [data]}) do
    attribute_type_and_value(data)
  end

  defp attribute_type_and_value(rdn_sequence, acc \\ %{})

  defp attribute_type_and_value([attr | attributes], acc)
       when Record.is_record(attr, :AttributeTypeAndValue) do
    type = attr |> elem(1) |> oid_alias()
    value = attr |> elem(2) |> munge_utf8()

    attribute_type_and_value(attributes, Map.put(acc, type, value))
  end

  defp attribute_type_and_value([], acc), do: acc

  defp oid_alias({2, 5, 4, 3}), do: :common_name
  defp oid_alias({2, 5, 4, 6}), do: :country
  defp oid_alias({2, 5, 4, 8}), do: :location
  defp oid_alias({2, 5, 4, 10}), do: :organization
  defp oid_alias(_oid_name), do: :unknown

  defp munge_utf8({:utf8String, data}), do: data
  defp munge_utf8(data) when is_list(data), do: List.to_string(data)
end
