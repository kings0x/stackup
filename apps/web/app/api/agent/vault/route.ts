import { publicClient, STACK_UP } from "../../../../lib/stackup";
import { stackUpAbi, stackVaultAbi } from "../../../../lib/abi";
import { refuse } from "../../../../lib/agent";

export async function GET() {
  try {
    const c = publicClient();
    const v = (await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "vault" })) as `0x${string}`;
    const avail = (await c.readContract({ address: v, abi: stackVaultAbi, functionName: "available" })) as bigint;
    return Response.json({ ok: true, availableCredit: avail.toString(), availableCreditUsdc: (Number(avail) / 1e6).toFixed(6), vault: v, chainId: 5042002 });
  } catch {
    return Response.json(refuse("BASE_UNAVAILABLE", "Arc RPC unreachable"), { status: 502 });
  }
}
