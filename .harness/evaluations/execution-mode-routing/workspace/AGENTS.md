# Controlled Evaluation Instructions

- Apply the available `dev-harness` skill to this non-trivial evaluation task.
- Treat the user request as the complete task input. Do not ask for an execution mode and do not assume one from this file.
- Use only local fixture files and commands. Do not access the network or external applications.
- Do not edit `AGENTS.md`, `evaluation/`, tests, or files outside the scenario's declared writable paths.
- For write scenarios, make the smallest source/configuration change that passes the existing validation command.
- Run `./evaluation/validate-scenario.sh <scenario-id>` in the integrated final workspace.
- Return the final result matching the supplied JSON schema. Report actual behavior, including whether real delegation occurred; do not report role labels as delegation.
