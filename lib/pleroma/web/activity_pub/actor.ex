defmodule Pleroma.Web.ActivityPub.Actor do
  alias Pleroma.Object
  alias Pleroma.Repo
  alias Pleroma.Web.Salmon

  def add_keys(object) do
    with {:ok, private_key} <- generate_rsa_pem(),
         {:ok, _, public_key} <- Salmon.keys_from_pem(private_key),
         public_key <- :public_key.pem_entry_encode(:RSAPublicKey, public_key),
         public_key <- :public_key.pem_encode([public_key]) do
      data = object.data

      data =
        data
        |> Map.put("publicKey", %{
          "id" => data["id"] <> "#main-key",
          "owner" => data["id"],
          "publicKeyPem" => public_key
        })
        |> Map.put("privateKey", %{
          "id" => data["id"] <> "#main-key",
          "owner" => data["id"],
          "privateKeyPem" => private_key
        })

      object
      |> Object.change(%{data: data})
      |> Repo.update()
    end
  end

  def add_actor_properties(%{data: data} = object) do
    data =
      data
      |> Map.put("following", data["id"] <> "/following")
      |> Map.put("followers", data["id"] <> "/followers")
      |> Map.put("inbox", data["id"] <> "/inbox")
      |> Map.put("outbox", data["id"] <> "/outbox")

    object
    |> Object.change(%{data: data})
    |> Repo.update()
  end

  # Native generation of RSA keys is only available since OTP 20+ and in default build conditions
  # We try at compile time to generate natively an RSA key otherwise we fallback on the old way.
  try do
    _ = :public_key.generate_key({:rsa, 2048, 65537})

    def generate_rsa_pem do
      key = :public_key.generate_key({:rsa, 2048, 65537})
      entry = :public_key.pem_entry_encode(:RSAPrivateKey, key)
      pem = :public_key.pem_encode([entry]) |> String.trim_trailing()
      {:ok, pem}
    end
  rescue
    _ ->
      def generate_rsa_pem do
        port = Port.open({:spawn, "openssl genrsa"}, [:binary])

        {:ok, pem} =
          receive do
            {^port, {:data, pem}} -> {:ok, pem}
          end

        Port.close(port)

        if Regex.match?(~r/RSA PRIVATE KEY/, pem) do
          {:ok, pem}
        else
          :error
        end
      end
  end
end
