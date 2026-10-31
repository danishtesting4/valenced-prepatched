#!/bin/bash
echo '{"arch":"all","publish":"false"}' | gh api repos/danishtesting4/valenced-prepatched/actions/workflows/ci.yml/dispatches -X POST -f ref=master -F inputs=@-
echo "Exit code: $?"
