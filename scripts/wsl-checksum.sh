#!/usr/bin/env bash
export PATH="$HOME/.foundry/bin:$PATH"
for a in 0xb823dd1180dd8d31493614b86f19e0a7d282c28d 0x6f1c3aa1356842d8df38e7c6ec0bf96badd95456 0xc41e67a92364353edbb6f9ee0537f8d685562628 0x29602a5895fab2c015a4840deff5e0550b990385; do
  echo -n "$a -> "
  cast to-checksum "$a"
done
echo CHECKSUM_DONE
