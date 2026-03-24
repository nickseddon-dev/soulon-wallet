import { SigningStargateClient } from "@cosmjs/stargate";
import { Grant, GenericAuthorization } from "cosmjs-types/cosmos/authz/v1beta1/authz.js";
import { MsgExec, MsgGrant, MsgRevoke } from "cosmjs-types/cosmos/authz/v1beta1/tx.js";
import { Timestamp } from "cosmjs-types/google/protobuf/timestamp.js";
import { broadcastWithRetry } from "../core/broadcast.js";
import { AuthzExecInput, AuthzGrantInput, AuthzRevokeInput } from "../core/types.js";

const toTimestamp = (date: Date): Timestamp => {
  const millis = date.getTime();
  return Timestamp.fromPartial({
    seconds: BigInt(Math.floor(millis / 1000)),
    nanos: (millis % 1000) * 1_000_000
  });
};

export const grantGenericAuthorization = async (
  client: SigningStargateClient,
  input: AuthzGrantInput
) => {
  const expiration = input.expiration ?? new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  return broadcastWithRetry(async () => {
    return client.signAndBroadcast(
      input.granterAddress,
      [
        {
          typeUrl: "/cosmos.authz.v1beta1.MsgGrant",
          value: MsgGrant.fromPartial({
            granter: input.granterAddress,
            grantee: input.granteeAddress,
            grant: Grant.fromPartial({
              authorization: {
                typeUrl: "/cosmos.authz.v1beta1.GenericAuthorization",
                value: GenericAuthorization.encode(
                  GenericAuthorization.fromPartial({
                    msg: input.msgTypeUrl
                  })
                ).finish()
              },
              expiration: toTimestamp(expiration)
            })
          })
        }
      ],
      "auto",
      input.memo ?? ""
    );
  });
};

export const executeAuthorizedMessages = async (
  client: SigningStargateClient,
  input: AuthzExecInput
) => {
  return broadcastWithRetry(async () => {
    return client.signAndBroadcast(
      input.granteeAddress,
      [
        {
          typeUrl: "/cosmos.authz.v1beta1.MsgExec",
          value: MsgExec.fromPartial({
            grantee: input.granteeAddress,
            msgs: input.messages.map((message) => ({
              typeUrl: message.typeUrl,
              value: message.value
            }))
          })
        }
      ],
      "auto",
      input.memo ?? ""
    );
  });
};

export const revokeAuthorization = async (
  client: SigningStargateClient,
  input: AuthzRevokeInput
) => {
  return broadcastWithRetry(async () => {
    return client.signAndBroadcast(
      input.granterAddress,
      [
        {
          typeUrl: "/cosmos.authz.v1beta1.MsgRevoke",
          value: MsgRevoke.fromPartial({
            granter: input.granterAddress,
            grantee: input.granteeAddress,
            msgTypeUrl: input.msgTypeUrl
          })
        }
      ],
      "auto",
      input.memo ?? ""
    );
  });
};
