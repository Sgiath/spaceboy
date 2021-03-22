defmodule Spaceboy.PeerCert do
  @moduledoc ~S"""
  Utility functions to ease the work with Peer Certificates
  """

  @type peer_cert :: binary() | atom()
  @type rdn :: %{
          subject: map(),
          issuer: map()
        }

  @doc ~S"""
  Extract RDN Sequences from certificate

  Dialyxir currently shows warnings because of bug in `:public_key` source code
  https://github.com/erlang/otp/issues/4650
  """
  @spec rdn(peer_cert :: peer_cert) :: rdn | :no_peercert
  def rdn(cert) when is_binary(cert) do
    with {_subject_sn, sub_rdn} <- :public_key.pkix_subject_id(cert),
         {:ok, {_issuer_sn, iss_rdn}} <- :public_key.pkix_issuer_id(cert, :self) do
      %{
        subject: rdn_sequence(sub_rdn),
        issuer: rdn_sequence(iss_rdn)
      }
    end
  end

  def rdn(:no_peercert), do: :no_peercert

  defp rdn_sequence({:rdnSequence, [attributes]}) do
    attribute_type_and_value(attributes)
  end

  defp attribute_type_and_value(rdn_sequence, acc \\ %{})

  defp attribute_type_and_value([{:AttributeTypeAndValue, type, value} | attributes], acc) do
    attribute_type_and_value(attributes, Map.put(acc, oid_alias(type), munge_utf8(value)))
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
