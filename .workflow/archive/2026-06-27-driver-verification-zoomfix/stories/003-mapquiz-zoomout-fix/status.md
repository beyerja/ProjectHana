status: done
depends_on: 001-driver-pinch-action, 002-bake-driver-into-verify-agents
blocks: none
note: MUST run last; verification uses `just ui-walkthrough` + the new `pinch` action
