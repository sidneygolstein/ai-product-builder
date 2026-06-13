---
description: Independent verification via verifier subagent. Use after /build. Runs baseline, tests, and browser verification against the slice definition_of_done.
---
Use the verifier subagent (did not write this code). Run ai/init.sh baseline check; run all tests;
run browser verification (Playwright MCP) for each AC state. Grade against the slice's
definition_of_done. Output pass / warn / block with evidence. Only on pass may status move to
TO REVIEW. On block, return concrete failures to /build.
