# Protocol: Angular Standards

On-demand, agent-owned language baseline for `coder` with `language=angular`.
Resolve this file against the injected `agent-system` reference, not the project.
Project facts, installed versions, architecture, commands, and explicit conventions
come from `docs/project.md`, the matched slice's primary doc, and relevant
`docs/context/*.md`; these take precedence over baseline suggestions here.

- Read `docs/context/architecture.md` and the project's Angular reactivity,
  resource/API, coding, and testing docs before implementation. Do not copy legacy
  source patterns over documented standards.
- Use the `angular-cli` MCP best-practices and documentation tools before choosing
  APIs or patterns; use supported MCP actions where available. Verify compatibility
  with the installed Angular version rather than assuming the newest API exists.
- Prefer strict TypeScript, focused typed components/services, standalone APIs,
  and OnPush where supported and consistent with project conventions. Avoid `any`
  and unsafe casts that conceal a contract mismatch.
- Keep derived state derived (signals/computed where the project uses them);
  use the documented async/resource strategy. Do not synchronize state with timers
  or effects when a derivation suffices. Clean up subscriptions and side effects.
- Keep templates declarative, accessible, and stable under list updates; use the
  project's supported control flow and tracking convention. Respect trust boundaries
  and never bypass sanitization to make untrusted content render.
- Test behavior, loading/error states, and regressions using the project's framework.
  Run the canonical package-level test/lint/typecheck/build commands, report actual
  results, and surface any unavailable verification instead of claiming success.

This baseline does not authorize framework migrations, new dependencies, architecture
changes, or deviations from project rules.
