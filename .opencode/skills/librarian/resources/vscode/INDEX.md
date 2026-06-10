<!-- @INDEX
domain: meta
type: index
level: all
topics: taxonomy, file-map, search, navigation
keywords: index, taxonomy, search, navigation, map, docs
-->

# GitHub Docs Index

> **Purpose**: AI-to-AI navigation index for `.opencode/docs/github/`.
> Every `.md` file in this tree contains an `<!-- @INDEX -->` tag block after its frontmatter.
> This file is the master registry. An agent can search by domain, type, level, topic, or keyword.

---

## Tag Format (per file)

```html
<!-- @INDEX
domain: <primary-domain>
type: <overview|tutorial|guide|reference|howto|troubleshooting|concept|faq|video|demo>
level: <beginner|intermediate|advanced|all>
topics: <comma-separated-topic-list>
keywords: <comma-separated-keyword-list>
-->
```

| Field      | Values                                                                                     |
|------------|--------------------------------------------------------------------------------------------|
| `domain`   | See [Domain Taxonomy](#domain-taxonomy)                                                    |
| `type`     | `overview` `tutorial` `guide` `reference` `howto` `troubleshooting` `concept` `faq` `video` `demo` |
| `level`    | `beginner` `intermediate` `advanced` `all`                                                  |
| `topics`   | Free-form, hyphenated, comma-separated                                                     |
| `keywords` | Free-form, hyphenated, comma-separated                                                     |

---

## Domain Taxonomy

| Domain                | Short Description                                                |
|-----------------------|------------------------------------------------------------------|
| `agents`              | AI agent concepts, types, sessions, guides, troubleshooting      |
| `agent-customization` | Custom instructions, agents, skills, hooks, prompt files, MCP    |
| `agent-native`        | Native VS Code agent features                                     |
| `chat`                | Copilot Chat, inline chat, checkpoints, artifacts, code review    |
| `copilot`             | GitHub Copilot setup and overview                                 |
| `extension-api`       | VS Code Extension API (build, publish, debug extensions)          |
| `editor`              | Core editor: UI, editing, refactoring, IntelliSense, snippets     |
| `configure`           | Settings, keybindings, themes, profiles, sync, locales            |
| `terminal`            | Integrated terminal: basics, profiles, shell integration          |
| `sourcecontrol`       | Git: staging, commits, branches, remotes, merge conflicts         |
| `debugtest`           | Debugging, testing, tasks, port forwarding, browser testing       |
| `languages`           | Language support overview (JS, TS, Python, Go, Rust, etc.)        |
| `typescript`          | TypeScript editing, debugging, refactoring, transpiling           |
| `python`              | Python editing, debugging, environments, linting, web frameworks  |
| `java`                | Java editing, debugging, Spring Boot, build, refactoring          |
| `csharp`              | C# editing, debugging, testing, IntelliCode                       |
| `nodejs`              | Node.js tutorials, debugging, deployment, profiling               |
| `cpp`                 | C++ configuration, debugging, IntelliSense, natvis                |
| `containers`          | Docker: build, debug, compose, Kubernetes, registries             |
| `devcontainers`       | Dev containers: create, configure, CLI, reference                 |
| `remote`              | Remote development: SSH, WSL, tunnels, server, web                |
| `azure`               | Azure: deployment, AKS, MongoDB, Kubernetes, web                  |
| `enterprise`          | Enterprise: policies, telemetry, extensions, AI settings          |
| `datascience`         | Jupyter, notebooks, PyTorch, data wrangler, Fabric                |
| `intelligentapps`     | AI toolkit: models, tracing, profiling, playground                |
| `setup`               | Installation: Windows, Mac, Linux, Raspberry Pi, portable         |
| `getstarted`          | Getting started: overview, tutorials, Copilot quickstart          |
| `learn-foundations`   | Learning path: agent-first development foundations                |
| `learn-customizations`| Learning path: customization tutorials                            |
| `reference`           | Reference: variables, tasks, default settings, keybindings        |
| `supporting`          | FAQ, requirements, OSS licenses, troubleshooting                  |
| `introvideos`         | Introductory video tutorials                                      |

---

## File Map

### agents (AI Agents)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/agents/overview.md` | overview | intermediate | agent-types, autonomous-coding, multi-file-editing |
| `docs/agents/agents-tutorial.md` | tutorial | beginner | first-agent, step-by-step |
| `docs/agents/agents-window.md` | howto | intermediate | agent-window, session-management |
| `docs/agents/agent-tools.md` | reference | intermediate | agent-tools, tool-calls |
| `docs/agents/best-practices.md` | guide | advanced | best-practices, prompt-engineering |
| `docs/agents/chat-view.md` | howto | beginner | chat-view, ui |
| `docs/agents/memory.md` | concept | intermediate | memory, context-persistence |
| `docs/agents/planning.md` | concept | intermediate | planning, task-decomposition |
| `docs/agents/security.md` | concept | intermediate | security, trust, sandboxing |
| `docs/agents/subagents.md` | concept | advanced | subagents, delegation, orchestration |
| `docs/agents/concepts/overview.md` | overview | beginner | agent-concepts |
| `docs/agents/concepts/agents.md` | concept | beginner | agent-loop, autonomous-coding |
| `docs/agents/concepts/context.md` | concept | intermediate | context-engineering, workspace-context |
| `docs/agents/concepts/customization.md` | concept | intermediate | customization, instructions, skills |
| `docs/agents/concepts/language-models.md` | concept | intermediate | language-models, model-selection |
| `docs/agents/concepts/tools.md` | concept | intermediate | tools, tool-calls, mcp |
| `docs/agents/concepts/trust-and-safety.md` | concept | intermediate | trust, safety, approvals |
| `docs/agents/agent-types/local-agents.md` | guide | beginner | local-agent, interactive |
| `docs/agents/agent-types/cloud-agents.md` | guide | intermediate | cloud-agent, background, github |
| `docs/agents/agent-types/copilot-cli.md` | guide | intermediate | copilot-cli, background-agent |
| `docs/agents/agent-types/third-party-agents.md` | guide | intermediate | third-party, extensions |
| `docs/agents/sessions/chat-sessions.md` | howto | beginner | chat-sessions, history |
| `docs/agents/sessions/session-insights.md` | howto | intermediate | session-insights, analytics |
| `docs/agents/sessions/session-sync.md` | howto | intermediate | session-sync, synchronization |
| `docs/agents/reference/copilot-settings.md` | reference | intermediate | settings, configuration |
| `docs/agents/reference/copilot-vscode-features.md` | reference | intermediate | features, capabilities |
| `docs/agents/reference/mcp-configuration.md` | reference | advanced | mcp, configuration, protocol |
| `docs/agents/reference/workspace-context.md` | reference | intermediate | workspace, context, files |
| `docs/agents/guides/browser-agent-testing-guide.md` | guide | advanced | browser-testing, web, e2e |
| `docs/agents/guides/code-review-with-copilot.md` | guide | intermediate | code-review, pull-request |
| `docs/agents/guides/context-engineering-guide.md` | guide | advanced | context-engineering, prompt-design |
| `docs/agents/guides/customize-copilot-guide.md` | tutorial | beginner | customization, setup |
| `docs/agents/guides/debug-with-copilot.md` | guide | intermediate | debugging, ai-assisted |
| `docs/agents/guides/mcp-developer-guide.md` | guide | advanced | mcp, developer, protocol |
| `docs/agents/guides/monitoring-agents.md` | guide | intermediate | monitoring, observability |
| `docs/agents/guides/notebooks-with-ai.md` | guide | intermediate | notebooks, jupyter, ai |
| `docs/agents/guides/optimize-usage.md` | guide | intermediate | optimization, efficiency |
| `docs/agents/guides/prompt-engineering-guide.md` | guide | advanced | prompt-engineering, techniques |
| `docs/agents/guides/prompt-examples.md` | reference | intermediate | prompt-examples, templates |
| `docs/agents/guides/test-driven-development-guide.md` | guide | intermediate | tdd, test-driven, ai |
| `docs/agents/guides/test-with-copilot.md` | guide | intermediate | testing, ai-assisted |
| `docs/agents/agent-troubleshooting/troubleshooting.md` | troubleshooting | intermediate | troubleshooting, errors |
| `docs/agents/agent-troubleshooting/faq.md` | faq | beginner | faq, common-issues |
| `docs/agents/agent-troubleshooting/chat-debug-view.md` | howto | advanced | debug-view, diagnostics |

### agent-customization (AI Customization)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/agent-customization/overview.md` | overview | beginner | customization, ai-setup |
| `docs/agent-customization/custom-instructions.md` | guide | beginner | instructions, rules, conventions |
| `docs/agent-customization/custom-agents.md` | guide | intermediate | custom-agents, roles, workflows |
| `docs/agent-customization/agent-skills.md` | guide | intermediate | skills, automation, reusable |
| `docs/agent-customization/agent-plugins.md` | guide | advanced | plugins, extensions, integration |
| `docs/agent-customization/hooks.md` | guide | intermediate | hooks, lifecycle, automation |
| `docs/agent-customization/prompt-files.md` | guide | beginner | prompt-files, templates, reuse |
| `docs/agent-customization/mcp-servers.md` | guide | advanced | mcp, servers, protocol |
| `docs/agent-customization/language-models.md` | guide | intermediate | language-models, model-config |

### agent-native

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/agent-native/overview.md` | overview | beginner | native-agent, vscode-agent |

### chat (Copilot Chat)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/chat/copilot-chat.md` | overview | beginner | chat, copilot, ai-assistant |
| `docs/chat/copilot-chat-context.md` | concept | intermediate | context, references, chat-context |
| `docs/chat/inline-chat.md` | howto | beginner | inline-chat, editor, quick-edit |
| `docs/chat/review-code-edits.md` | howto | intermediate | code-review, diff, chat |
| `docs/chat/chat-checkpoints.md` | concept | intermediate | checkpoints, rollback, history |
| `docs/chat/chat-artifacts.md` | concept | intermediate | artifacts, generated-content |

### copilot (GitHub Copilot)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/copilot/overview.md` | overview | beginner | copilot, ai, setup |
| `docs/copilot/setup-simplified.md` | tutorial | beginner | copilot-setup, installation |

### extension-api (VS Code Extension API)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `api/index.md` | overview | beginner | extension-api, overview |
| `api/get-started/your-first-extension.md` | tutorial | beginner | first-extension, hello-world |
| `api/get-started/extension-anatomy.md` | concept | beginner | extension-structure, anatomy |
| `api/get-started/wrapping-up.md` | guide | beginner | next-steps, publishing |
| `api/extension-capabilities/overview.md` | overview | intermediate | capabilities, api-overview |
| `api/extension-capabilities/common-capabilities.md` | reference | intermediate | commands, configuration, events |
| `api/extension-capabilities/theming.md` | guide | intermediate | themes, colors, icons |
| `api/extension-capabilities/extending-workbench.md` | guide | advanced | workbench, ui-components |
| `api/extension-guides/overview.md` | overview | intermediate | extension-guides |
| `api/extension-guides/ai/ai-extensibility-overview.md` | overview | advanced | ai-extensibility, lm-api, chat-api |
| `api/extension-guides/ai/tools.md` | guide | advanced | language-model-tools, tools-api |
| `api/extension-guides/ai/mcp.md` | guide | advanced | mcp, extension, protocol |
| `api/extension-guides/ai/chat.md` | guide | advanced | chat-participant, chat-api |
| `api/extension-guides/ai/chat-tutorial.md` | tutorial | advanced | chat-tutorial, step-by-step |
| `api/extension-guides/ai/language-model.md` | guide | advanced | language-model, lm-api |
| `api/extension-guides/ai/language-model-tutorial.md` | tutorial | advanced | lm-tutorial, step-by-step |
| `api/extension-guides/ai/language-model-chat-provider.md` | guide | advanced | chat-provider, model-provider |
| `api/extension-guides/ai/prompt-tsx.md` | guide | advanced | prompt-tsx, jsx, templates |
| `api/extension-guides/command.md` | guide | intermediate | commands, registration |
| `api/extension-guides/color-theme.md` | guide | intermediate | color-theme, theming |
| `api/extension-guides/file-icon-theme.md` | guide | intermediate | file-icons, theming |
| `api/extension-guides/product-icon-theme.md` | guide | intermediate | product-icons, theming |
| `api/extension-guides/tree-view.md` | guide | intermediate | tree-view, sidebar |
| `api/extension-guides/webview.md` | guide | advanced | webview, html, ui |
| `api/extension-guides/notebook.md` | guide | advanced | notebook, jupyter |
| `api/extension-guides/custom-editors.md` | guide | advanced | custom-editors, ui |
| `api/extension-guides/virtual-documents.md` | guide | advanced | virtual-documents, content-provider |
| `api/extension-guides/virtual-workspaces.md` | guide | advanced | virtual-workspaces, remote |
| `api/extension-guides/web-extensions.md` | guide | advanced | web-extensions, browser |
| `api/extension-guides/workspace-trust.md` | guide | intermediate | workspace-trust, security |
| `api/extension-guides/task-provider.md` | guide | intermediate | tasks, task-provider |
| `api/extension-guides/scm-provider.md` | guide | advanced | scm, source-control, git |
| `api/extension-guides/debugger-extension.md` | guide | advanced | debugger, debug-adapter |
| `api/extension-guides/markdown-extension.md` | guide | intermediate | markdown, preview |
| `api/extension-guides/testing.md` | guide | intermediate | testing, test-api |
| `api/extension-guides/custom-data-extension.md` | guide | advanced | custom-data, html, css |
| `api/extension-guides/telemetry.md` | guide | intermediate | telemetry, analytics |
| `api/ux-guidelines/overview.md` | overview | intermediate | ux, design, guidelines |
| `api/ux-guidelines/activity-bar.md` | reference | intermediate | activity-bar, ui |
| `api/ux-guidelines/sidebars.md` | reference | intermediate | sidebar, panel, ui |
| `api/ux-guidelines/panel.md` | reference | intermediate | panel, ui |
| `api/ux-guidelines/status-bar.md` | reference | intermediate | status-bar, ui |
| `api/ux-guidelines/views.md` | reference | intermediate | views, sidebar, ui |
| `api/ux-guidelines/editor-actions.md` | reference | intermediate | editor-actions, context-menu |
| `api/ux-guidelines/quick-picks.md` | reference | intermediate | quick-pick, command-palette |
| `api/ux-guidelines/command-palette.md` | reference | intermediate | command-palette, ui |
| `api/ux-guidelines/notifications.md` | reference | intermediate | notifications, messages |
| `api/ux-guidelines/webviews.md` | reference | advanced | webview, ui, html |
| `api/ux-guidelines/context-menus.md` | reference | intermediate | context-menu, right-click |
| `api/ux-guidelines/walkthroughs.md` | reference | intermediate | walkthroughs, onboarding |
| `api/ux-guidelines/settings.md` | reference | intermediate | settings, configuration-ui |
| `api/references/activation-events.md` | reference | advanced | activation-events, package.json |
| `api/references/commands.md` | reference | intermediate | built-in-commands |
| `api/references/contribution-points.md` | reference | advanced | contribution-points, package.json |
| `api/references/document-selector.md` | reference | advanced | document-selector, scheme |
| `api/references/extension-manifest.md` | reference | intermediate | package.json, manifest |
| `api/references/icons-in-labels.md` | reference | intermediate | icons, codicons, labels |
| `api/references/theme-color.md` | reference | intermediate | theme-color, theming |
| `api/references/when-clause-contexts.md` | reference | advanced | when-clause, context, conditions |
| `api/language-extensions/overview.md` | overview | intermediate | language-extensions |
| `api/language-extensions/syntax-highlight-guide.md` | guide | advanced | syntax-highlight, textmate |
| `api/language-extensions/snippet-guide.md` | guide | intermediate | snippets, templates |
| `api/language-extensions/semantic-highlight-guide.md` | guide | advanced | semantic-highlight, tokens |
| `api/language-extensions/programmatic-language-features.md` | guide | advanced | language-features, intellisense |
| `api/language-extensions/language-server-extension-guide.md` | guide | advanced | language-server, lsp |
| `api/language-extensions/language-configuration-guide.md` | guide | intermediate | language-configuration, grammar |
| `api/language-extensions/embedded-languages.md` | guide | advanced | embedded-languages, multi-language |
| `api/working-with-extensions/testing-extension.md` | guide | intermediate | extension-testing, ci |
| `api/working-with-extensions/publishing-extension.md` | guide | intermediate | publishing, marketplace |
| `api/working-with-extensions/continuous-integration.md` | guide | intermediate | ci, github-actions, azure-pipelines |
| `api/working-with-extensions/bundling-extension.md` | guide | intermediate | bundling, webpack, esbuild |
| `api/advanced-topics/using-proposed-api.md` | guide | advanced | proposed-api, unstable |
| `api/advanced-topics/tslint-eslint-migration.md` | guide | intermediate | tslint, eslint, migration |
| `api/advanced-topics/remote-extensions.md` | guide | advanced | remote-development, extensions |
| `api/advanced-topics/python-extension-template.md` | guide | advanced | python-extension, template |
| `api/advanced-topics/extension-host.md` | concept | advanced | extension-host, architecture |

### editor (Core Editor)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/editor/whyvscode.md` | overview | beginner | vscode, comparison, features |
| `docs/editor/glob-patterns.md` | reference | intermediate | glob, patterns, file-matching |
| `docs/editing/userinterface.md` | overview | beginner | ui, layout, sidebar |
| `docs/editing/intellisense.md` | concept | beginner | intellisense, autocomplete, suggestions |
| `docs/editing/refactoring.md` | howto | intermediate | refactoring, rename, extract |
| `docs/editing/tips-and-tricks.md` | reference | intermediate | tips, shortcuts, productivity |
| `docs/editing/userdefinedsnippets.md` | guide | beginner | snippets, templates, custom |
| `docs/editing/workspaces/workspaces.md` | overview | beginner | workspaces, folders |
| `docs/editing/workspaces/workspace-trust.md` | concept | intermediate | workspace-trust, security |
| `docs/editing/workspaces/multi-root-workspaces.md` | guide | intermediate | multi-root, workspaces |
| `docs/customization/keyboard-shortcuts.md` | reference | beginner | keybindings, shortcuts |

### configure (Settings & Configuration)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/configure/settings.md` | overview | beginner | settings, configuration |
| `docs/configure/keybindings.md` | guide | beginner | keybindings, shortcuts |
| `docs/configure/themes.md` | guide | beginner | themes, colors, appearance |
| `docs/configure/settings-sync.md` | howto | beginner | sync, settings-sync, cloud |
| `docs/configure/profiles.md` | guide | intermediate | profiles, workspace-profiles |
| `docs/configure/locales.md` | guide | beginner | locales, language, i18n |
| `docs/configure/telemetry.md` | reference | intermediate | telemetry, data, privacy |

### terminal (Integrated Terminal)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/terminal/getting-started.md` | tutorial | beginner | terminal, first-command |
| `docs/terminal/basics.md` | overview | beginner | terminal-basics, commands |
| `docs/terminal/profiles.md` | guide | intermediate | profiles, shell-config |
| `docs/terminal/shell-integration.md` | concept | intermediate | shell-integration, decorations |
| `docs/terminal/appearance.md` | guide | intermediate | appearance, fonts, colors |
| `docs/terminal/advanced.md` | reference | advanced | persistent-sessions, unicode |

### sourcecontrol (Git & Source Control)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/sourcecontrol/overview.md` | overview | beginner | git, scm, source-control |
| `docs/sourcecontrol/quickstart.md` | tutorial | beginner | git-quickstart, init, commit |
| `docs/sourcecontrol/staging-commits.md` | guide | beginner | staging, commits, diff |
| `docs/sourcecontrol/branches-worktrees.md` | guide | intermediate | branches, worktrees, stash |
| `docs/sourcecontrol/repos-remotes.md` | guide | intermediate | remotes, clone, push, pull |
| `docs/sourcecontrol/merge-conflicts.md` | guide | intermediate | merge-conflicts, 3-way-merge |
| `docs/sourcecontrol/github.md` | guide | intermediate | github, pull-requests, issues |
| `docs/sourcecontrol/troubleshooting.md` | troubleshooting | intermediate | git-troubleshooting, logs |
| `docs/sourcecontrol/faq.md` | faq | beginner | git-faq, common-questions |

### debugtest (Debugging & Testing)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/debugtest/debugging.md` | overview | beginner | debugging, breakpoints, launch |
| `docs/debugtest/debugging-configuration.md` | reference | intermediate | launch-json, debug-config |
| `docs/debugtest/testing.md` | overview | intermediate | testing, test-explorer |
| `docs/debugtest/tasks.md` | guide | intermediate | tasks, build-tasks, automation |
| `docs/debugtest/port-forwarding.md` | howto | intermediate | port-forwarding, remote |
| `docs/debugtest/integrated-browser.md` | howto | intermediate | browser, integrated-browser |

### languages (Language Support)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/languages/overview.md` | overview | beginner | languages, overview |
| `docs/languages/javascript.md` | guide | beginner | javascript, node |
| `docs/languages/typescript.md` | guide | beginner | typescript |
| `docs/languages/python.md` | guide | beginner | python |
| `docs/languages/go.md` | guide | beginner | go, golang |
| `docs/languages/java.md` | guide | beginner | java |
| `docs/languages/csharp.md` | guide | beginner | csharp, dotnet |
| `docs/languages/cpp.md` | guide | beginner | cpp, c++ |
| `docs/languages/rust.md` | guide | beginner | rust |
| `docs/languages/ruby.md` | guide | beginner | ruby |
| `docs/languages/php.md` | guide | beginner | php |
| `docs/languages/css.md` | guide | beginner | css, scss, less |
| `docs/languages/html.md` | guide | beginner | html |
| `docs/languages/json.md` | guide | beginner | json |
| `docs/languages/markdown.md` | guide | beginner | markdown |
| `docs/languages/dotnet.md` | guide | beginner | dotnet, csharp, fsharp |
| `docs/languages/powershell.md` | guide | beginner | powershell |
| `docs/languages/r.md` | guide | beginner | r-language |
| `docs/languages/julia.md` | guide | beginner | julia |
| `docs/languages/swift.md` | guide | beginner | swift |
| `docs/languages/tsql.md` | guide | beginner | tsql, sql |
| `docs/languages/emmet.md` | guide | beginner | emmet, html, css |
| `docs/languages/identifiers.md` | reference | intermediate | language-identifiers |
| `docs/languages/jsconfig.md` | reference | intermediate | jsconfig, javascript-config |

### typescript

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/typescript/typescript-tutorial.md` | tutorial | beginner | typescript, tutorial |
| `docs/typescript/typescript-editing.md` | guide | intermediate | typescript-editing, intellisense |
| `docs/typescript/typescript-debugging.md` | guide | intermediate | typescript-debugging, source-maps |
| `docs/typescript/typescript-refactoring.md` | guide | intermediate | typescript-refactoring, rename |
| `docs/typescript/typescript-transpiling.md` | guide | intermediate | typescript-compiler, tsc |

### python

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/python/python-quick-start.md` | tutorial | beginner | python, quickstart |
| `docs/python/python-tutorial.md` | tutorial | beginner | python, tutorial |
| `docs/python/editing.md` | guide | intermediate | python-editing, intellisense |
| `docs/python/debugging.md` | guide | intermediate | python-debugging |
| `docs/python/environments.md` | guide | intermediate | python-environments, venv, conda |
| `docs/python/linting.md` | guide | intermediate | python-linting, pylint, flake8 |
| `docs/python/testing.md` | guide | intermediate | python-testing, pytest, unittest |
| `docs/python/run.md` | howto | beginner | python-run, execute |
| `docs/python/python-web.md` | guide | intermediate | python-web, flask, django |
| `docs/python/python-on-azure.md` | guide | intermediate | python-azure, deployment |
| `docs/python/tutorial-flask.md` | tutorial | intermediate | flask, tutorial, web |
| `docs/python/tutorial-fastapi.md` | tutorial | intermediate | fastapi, tutorial, api |
| `docs/python/tutorial-django.md` | tutorial | intermediate | django, tutorial, web |
| `docs/python/tutorial-create-containers.md` | tutorial | intermediate | python-containers, docker |
| `docs/python/jupyter-support-py.md` | guide | intermediate | jupyter, notebooks, python |
| `docs/python/settings-reference.md` | reference | intermediate | python-settings, configuration |

### java

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/java/java-tutorial.md` | tutorial | beginner | java, tutorial |
| `docs/java/java-editing.md` | guide | intermediate | java-editing, refactoring |
| `docs/java/java-debugging.md` | guide | intermediate | java-debugging |
| `docs/java/java-testing.md` | guide | intermediate | java-testing, junit |
| `docs/java/java-project.md` | guide | intermediate | java-project, maven, gradle |
| `docs/java/java-build.md` | guide | intermediate | java-build, maven, gradle |
| `docs/java/java-linting.md` | guide | intermediate | java-linting, formatting |
| `docs/java/java-refactoring.md` | guide | intermediate | java-refactoring |
| `docs/java/java-spring-boot.md` | guide | intermediate | spring-boot, java |
| `docs/java/java-spring-apps.md` | guide | intermediate | spring, microservices |
| `docs/java/java-webapp.md` | guide | intermediate | java-web, servlet |
| `docs/java/java-tomcat-jetty.md` | guide | intermediate | tomcat, jetty, server |
| `docs/java/java-on-azure.md` | guide | intermediate | java-azure, deployment |
| `docs/java/java-gui.md` | guide | intermediate | java-gui, javafx, swing |
| `docs/java/java-app-mod.md` | guide | advanced | java-modernization, migration |
| `docs/java/java-faq.md` | faq | beginner | java-faq |

### csharp

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/csharp/navigate-edit.md` | guide | beginner | csharp-editing, navigation |
| `docs/csharp/intellicode.md` | guide | intermediate | intellicode, ai-completion |
| `docs/csharp/testing.md` | guide | intermediate | csharp-testing, nunit, xunit |
| `docs/csharp/refactoring.md` | guide | intermediate | csharp-refactoring |
| `docs/csharp/project-management.md` | guide | intermediate | csharp-project, nuget |
| `docs/csharp/package-management.md` | guide | intermediate | nuget, packages |
| `docs/csharp/signing-in.md` | howto | beginner | csharp-signin, azure |
| `docs/csharp/introvideos-csharp.md` | video | beginner | csharp-video, tutorial |

### nodejs

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/nodejs/nodejs-tutorial.md` | tutorial | beginner | nodejs, tutorial |
| `docs/nodejs/working-with-javascript.md` | guide | intermediate | javascript, node |
| `docs/nodejs/nodejs-debugging.md` | guide | intermediate | nodejs-debugging |
| `docs/nodejs/nodejs-deployment.md` | guide | intermediate | nodejs-deployment, azure |
| `docs/nodejs/profiling.md` | guide | advanced | profiling, performance |
| `docs/nodejs/reactjs-tutorial.md` | tutorial | intermediate | react, tutorial |
| `docs/nodejs/vuejs-tutorial.md` | tutorial | intermediate | vuejs, tutorial |

### cpp

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/cpp/config-msvc.md` | guide | intermediate | cpp, msvc, windows |
| `docs/cpp/config-mingw.md` | guide | intermediate | cpp, mingw, windows |
| `docs/cpp/config-wsl.md` | guide | intermediate | cpp, wsl, linux |
| `docs/cpp/configure-intellisense-crosscompilation.md` | guide | advanced | cpp, intellisense, cross-compile |
| `docs/cpp/launch-json-reference.md` | reference | advanced | cpp, launch-json, debug-config |
| `docs/cpp/natvis.md` | guide | advanced | cpp, natvis, visualization |
| `docs/cpp/lldb-mi.md` | guide | advanced | cpp, lldb, debugger |
| `docs/cpp/pipe-transport.md` | guide | advanced | cpp, pipe-transport, remote-debug |
| `docs/cpp/introvideos-cpp.md` | video | beginner | cpp, video, tutorial |

### containers (Docker)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/containers/overview.md` | overview | beginner | docker, containers |
| `docs/containers/quickstart-node.md` | tutorial | intermediate | docker, nodejs |
| `docs/containers/quickstart-python.md` | tutorial | intermediate | docker, python |
| `docs/containers/quickstart-aspnet-core.md` | tutorial | intermediate | docker, aspnet |
| `docs/containers/quickstart-container-registries.md` | guide | intermediate | container-registries, acr |
| `docs/containers/debug-common.md` | guide | intermediate | docker-debug, multi-language |
| `docs/containers/debug-node.md` | guide | intermediate | docker-debug, nodejs |
| `docs/containers/debug-python.md` | guide | intermediate | docker-debug, python |
| `docs/containers/debug-netcore.md` | guide | intermediate | docker-debug, dotnet |
| `docs/containers/docker-compose.md` | guide | intermediate | docker-compose, multi-container |
| `docs/containers/bridge-to-kubernetes.md` | guide | advanced | bridge, kubernetes, debug |
| `docs/containers/choosing-dev-environment.md` | guide | intermediate | dev-environment, docker, devcontainer |
| `docs/containers/app-service.md` | guide | intermediate | azure-app-service, deployment |
| `docs/containers/ssh.md` | guide | advanced | docker, ssh, remote |
| `docs/containers/troubleshooting.md` | troubleshooting | intermediate | docker-troubleshooting |
| `docs/containers/reference.md` | reference | intermediate | docker-settings, tasks |
| `docs/containers/tutorial-django-push-to-registry.md` | tutorial | intermediate | django, docker, registry |

### devcontainers

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/devcontainers/containers.md` | overview | beginner | devcontainers, overview |
| `docs/devcontainers/tutorial.md` | tutorial | beginner | devcontainer-tutorial |
| `docs/devcontainers/create-dev-container.md` | guide | intermediate | create-devcontainer, dockerfile |
| `docs/devcontainers/devcontainerjson-reference.md` | reference | advanced | devcontainer.json, reference |
| `docs/devcontainers/devcontainer-cli.md` | reference | intermediate | devcontainer-cli, commands |
| `docs/devcontainers/attach-container.md` | howto | intermediate | attach, running-container |
| `docs/devcontainers/containers-advanced.md` | guide | advanced | devcontainer-advanced, tips |
| `docs/devcontainers/tips-and-tricks.md` | guide | intermediate | devcontainer-tips |
| `docs/devcontainers/faq.md` | faq | beginner | devcontainer-faq |

### remote (Remote Development)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/remote/remote-overview.md` | overview | beginner | remote-development, ssh, wsl, containers |
| `docs/remote/ssh.md` | guide | intermediate | ssh, remote, connection |
| `docs/remote/ssh-tutorial.md` | tutorial | beginner | ssh-tutorial |
| `docs/remote/wsl.md` | guide | intermediate | wsl, windows-subsystem-linux |
| `docs/remote/wsl-tutorial.md` | tutorial | beginner | wsl-tutorial |
| `docs/remote/tunnels.md` | guide | intermediate | tunnels, remote-access |
| `docs/remote/vscode-server.md` | concept | intermediate | vscode-server, architecture |
| `docs/remote/vscode-web.md` | overview | beginner | vscode-web, browser |
| `docs/remote/linux.md` | guide | intermediate | linux, remote, setup |
| `docs/remote/troubleshooting.md` | troubleshooting | intermediate | remote-troubleshooting |

### azure

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/azure/overview.md` | overview | beginner | azure, cloud |
| `docs/azure/deployment.md` | guide | intermediate | azure-deployment |
| `docs/azure/containers.md` | guide | intermediate | azure-containers, aci |
| `docs/azure/aksextensions.md` | guide | advanced | aks, kubernetes, extensions |
| `docs/azure/kubernetes.md` | guide | advanced | kubernetes, aks |
| `docs/azure/mongodb.md` | guide | intermediate | mongodb, azure-cosmos |
| `docs/azure/remote-debugging.md` | guide | advanced | remote-debugging, azure |
| `docs/azure/resourcesextension.md` | guide | intermediate | azure-resources, extension |
| `docs/azure/vscodeforweb.md` | overview | beginner | vscode-web, github-codespaces |

### enterprise

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/enterprise/overview.md` | overview | intermediate | enterprise, admin |
| `docs/enterprise/policies.md` | reference | advanced | group-policies, admin |
| `docs/enterprise/policies.template.md` | reference | advanced | policies-template |
| `docs/enterprise/extensions.md` | guide | intermediate | enterprise-extensions, marketplace |
| `docs/enterprise/telemetry.md` | concept | intermediate | enterprise-telemetry, data |
| `docs/enterprise/ai-settings.md` | guide | intermediate | ai-settings, copilot-admin |
| `docs/enterprise/updates.md` | guide | intermediate | enterprise-updates, deployment |

### datascience

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/datascience/overview.md` | overview | beginner | data-science, jupyter |
| `docs/datascience/jupyter-notebooks.md` | guide | beginner | jupyter, notebooks |
| `docs/datascience/jupyter-kernel-management.md` | guide | intermediate | jupyter-kernel, python |
| `docs/datascience/notebooks-web.md` | guide | intermediate | notebooks-web, vscode-web |
| `docs/datascience/python-interactive.md` | guide | intermediate | python-interactive, repl |
| `docs/datascience/pytorch-support.md` | guide | intermediate | pytorch, gpu, training |
| `docs/datascience/data-wrangler.md` | guide | intermediate | data-wrangler, data-cleaning |
| `docs/datascience/data-wrangler-quick-start.md` | tutorial | beginner | data-wrangler-quickstart |
| `docs/datascience/data-science-tutorial.md` | tutorial | beginner | data-science-tutorial |
| `docs/datascience/azure-machine-learning.md` | guide | advanced | azure-ml, cloud-training |
| `docs/datascience/microsoft-fabric-quickstart.md` | tutorial | intermediate | fabric, analytics |

### intelligentapps (AI Toolkit)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/intelligentapps/overview.md` | overview | intermediate | ai-toolkit, intelligent-apps |
| `docs/intelligentapps/models.md` | concept | intermediate | ai-models, llm |
| `docs/intelligentapps/modelconversion.md` | guide | advanced | model-conversion, onnx, quantization |
| `docs/intelligentapps/playground.md` | howto | intermediate | model-playground, testing |
| `docs/intelligentapps/tool-catalog.md` | reference | intermediate | tool-catalog, ai-tools |
| `docs/intelligentapps/tracing.md` | guide | advanced | tracing, diagnostics |
| `docs/intelligentapps/profiling.md` | guide | advanced | profiling, performance |
| `docs/intelligentapps/reference/TemplateProject.md` | reference | intermediate | template, project-structure |
| `docs/intelligentapps/reference/FileStructure.md` | reference | intermediate | file-structure, project |
| `docs/intelligentapps/reference/SetupWithoutAITK.md` | guide | advanced | setup, manual, no-aitk |
| `docs/intelligentapps/reference/ManualModelConversion.md` | guide | advanced | manual-conversion, onnx |
| `docs/intelligentapps/reference/ManualConversionOnGPU.md` | guide | advanced | gpu-conversion, cuda |
| `docs/intelligentapps/reference/UpdateModelProject.md` | guide | intermediate | update-model, project |
| `docs/intelligentapps/reference/migrate-from-visualizer.md` | guide | intermediate | migration, visualizer |

### setup (Installation)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/setup/windows.md` | tutorial | beginner | windows, install |
| `docs/setup/mac.md` | tutorial | beginner | mac, install |
| `docs/setup/linux.md` | tutorial | beginner | linux, install |
| `docs/setup/raspberry-pi.md` | tutorial | intermediate | raspberry-pi, arm |
| `docs/setup/portable.md` | guide | intermediate | portable-mode, usb |
| `docs/setup/network.md` | reference | intermediate | network, proxy, firewall |
| `docs/setup/uninstall.md` | guide | beginner | uninstall, cleanup |

### getstarted (Getting Started)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/getstarted/overview.md` | overview | beginner | getting-started, overview |
| `docs/getstarted/getting-started.md` | tutorial | beginner | first-steps, tutorial |
| `docs/getstarted/copilot-quickstart.md` | tutorial | beginner | copilot, quickstart |
| `docs/getstarted/personalize-vscode.md` | guide | beginner | personalization, themes, extensions |
| `docs/getstarted/introvideos.md` | video | beginner | intro-videos |
| `docs/getstarted/educators-and-students.md` | overview | beginner | education, students, teachers |

### learn-foundations (Learning: Agent Foundations)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `learn/foundations/introduction-to-agent-first-development.md` | tutorial | beginner | agent-first, five-pillars, harness |
| `learn/foundations/approvals-autonomy-and-context-budget.md` | tutorial | beginner | approvals, autonomy, context-budget |
| `learn/foundations/reviewing-and-controlling-agent-changes.md` | tutorial | beginner | review-changes, diff, checkpoints |
| `learn/foundations/agent-sessions-and-where-agents-run.md` | tutorial | beginner | sessions, local, cloud, cli |
| `learn/foundations/debugging-and-whats-happening-behind-the-scenes.md` | tutorial | intermediate | agent-debug, debug-logs |
| `learn/foundations/build-your-first-app-with-agent-mode.md` | tutorial | intermediate | first-app, fastapi, url-shortener |

### learn-customizations (Learning: Customizations)

| File | Type | Level | Topics |
|------|------|-------|--------|
| `learn/customizations/1-why-customization-matter.md` | tutorial | beginner | customization-why, agent-config |
| `learn/customizations/2-instructions.md` | tutorial | beginner | custom-instructions, rules |
| `learn/customizations/3-skills.md` | tutorial | beginner | agent-skills, automation |
| `learn/customizations/4-custom-agent.md` | tutorial | intermediate | custom-agents, roles |
| `learn/customizations/5-hooks.md` | tutorial | intermediate | hooks, lifecycle, events |
| `learn/customizations/6-prompt-files.md` | tutorial | beginner | prompt-files, templates |
| `learn/customizations/7-customization-features-explained.md` | concept | intermediate | customization-comparison, features |
| `learn/customizations/8-demo.md` | demo | intermediate | customization-demo, full-workflow |

### reference

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/reference/variables-reference.md` | reference | advanced | variables, input-variables, predefined |
| `docs/reference/tasks-appendix.md` | reference | intermediate | tasks, examples, templates |
| `docs/reference/default-settings.md` | reference | intermediate | default-settings, configuration |
| `docs/reference/default-keybindings.md` | reference | intermediate | default-keybindings, shortcuts |

### supporting

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/supporting/faq.md` | faq | beginner | faq, general |
| `docs/supporting/requirements.md` | reference | beginner | requirements, hardware, platform |
| `docs/supporting/oss-extensions.md` | reference | intermediate | oss, licenses, extensions |
| `docs/supporting/troubleshoot-terminal-launch.md` | troubleshooting | intermediate | terminal-troubleshooting, launch |

### introvideos

| File | Type | Level | Topics |
|------|------|-------|--------|
| `docs/introvideos/basics.md` | video | beginner | video-basics, first-steps |
| `docs/introvideos/codeediting.md` | video | beginner | video-editing, code |
| `docs/introvideos/configure.md` | video | beginner | video-configure, settings |
| `docs/introvideos/customize.md` | video | beginner | video-customize, themes |
| `docs/introvideos/debugging.md` | video | beginner | video-debugging |
| `docs/introvideos/extend.md` | video | beginner | video-extensions |
| `docs/introvideos/productivity.md` | video | beginner | video-productivity, tips |
| `docs/introvideos/versioncontrol.md` | video | beginner | video-git, source-control |

---

## Quick Lookup by Task

| I want to... | Start here |
|---|---|
| Understand AI agents in VS Code | `docs/agents/overview.md` |
| Build my first agent session | `learn/foundations/introduction-to-agent-first-development.md` |
| Customize AI behavior | `docs/agent-customization/overview.md` |
| Learn customization step-by-step | `learn/customizations/1-why-customization-matter.md` |
| Use Copilot Chat | `docs/chat/copilot-chat.md` |
| Set up GitHub Copilot | `docs/copilot/setup-simplified.md` |
| Build a VS Code extension | `api/get-started/your-first-extension.md` |
| Add AI to my extension | `api/extension-guides/ai/ai-extensibility-overview.md` |
| Configure MCP servers | `docs/agent-customization/mcp-servers.md` |
| Debug with AI | `docs/agents/guides/debug-with-copilot.md` |
| Test with AI | `docs/agents/guides/test-with-copilot.md` |
| Review code with AI | `docs/agents/guides/code-review-with-copilot.md` |
| Engineer prompts | `docs/agents/guides/prompt-engineering-guide.md` |
| Engineer context | `docs/agents/guides/context-engineering-guide.md` |
| Use Git in VS Code | `docs/sourcecontrol/overview.md` |
| Debug code | `docs/debugtest/debugging.md` |
| Set up terminal | `docs/terminal/getting-started.md` |
| Use dev containers | `docs/devcontainers/containers.md` |
| Work remotely | `docs/remote/remote-overview.md` |
| Deploy to Azure | `docs/azure/overview.md` |
| Use Docker | `docs/containers/overview.md` |
| Set up Python | `docs/python/python-quick-start.md` |
| Set up Java | `docs/java/java-tutorial.md` |
| Set up Node.js | `docs/nodejs/nodejs-tutorial.md` |
| Use Jupyter notebooks | `docs/datascience/jupyter-notebooks.md` |
| Configure enterprise policies | `docs/enterprise/policies.md` |

---

## Tag Index (by domain)

### agents (44 files)
`docs/agents/overview.md`, `docs/agents/agents-tutorial.md`, `docs/agents/agents-window.md`, `docs/agents/agent-tools.md`, `docs/agents/best-practices.md`, `docs/agents/chat-view.md`, `docs/agents/memory.md`, `docs/agents/planning.md`, `docs/agents/security.md`, `docs/agents/subagents.md`, `docs/agents/concepts/overview.md`, `docs/agents/concepts/agents.md`, `docs/agents/concepts/context.md`, `docs/agents/concepts/customization.md`, `docs/agents/concepts/language-models.md`, `docs/agents/concepts/tools.md`, `docs/agents/concepts/trust-and-safety.md`, `docs/agents/agent-types/local-agents.md`, `docs/agents/agent-types/cloud-agents.md`, `docs/agents/agent-types/copilot-cli.md`, `docs/agents/agent-types/third-party-agents.md`, `docs/agents/sessions/chat-sessions.md`, `docs/agents/sessions/session-insights.md`, `docs/agents/sessions/session-sync.md`, `docs/agents/reference/copilot-settings.md`, `docs/agents/reference/copilot-vscode-features.md`, `docs/agents/reference/mcp-configuration.md`, `docs/agents/reference/workspace-context.md`, `docs/agents/guides/browser-agent-testing-guide.md`, `docs/agents/guides/code-review-with-copilot.md`, `docs/agents/guides/context-engineering-guide.md`, `docs/agents/guides/customize-copilot-guide.md`, `docs/agents/guides/debug-with-copilot.md`, `docs/agents/guides/mcp-developer-guide.md`, `docs/agents/guides/monitoring-agents.md`, `docs/agents/guides/notebooks-with-ai.md`, `docs/agents/guides/optimize-usage.md`, `docs/agents/guides/prompt-engineering-guide.md`, `docs/agents/guides/prompt-examples.md`, `docs/agents/guides/test-driven-development-guide.md`, `docs/agents/guides/test-with-copilot.md`, `docs/agents/agent-troubleshooting/troubleshooting.md`, `docs/agents/agent-troubleshooting/faq.md`, `docs/agents/agent-troubleshooting/chat-debug-view.md`

### agent-customization (9 files)
`docs/agent-customization/overview.md`, `docs/agent-customization/custom-instructions.md`, `docs/agent-customization/custom-agents.md`, `docs/agent-customization/agent-skills.md`, `docs/agent-customization/agent-plugins.md`, `docs/agent-customization/hooks.md`, `docs/agent-customization/prompt-files.md`, `docs/agent-customization/mcp-servers.md`, `docs/agent-customization/language-models.md`

### chat (6 files)
`docs/chat/copilot-chat.md`, `docs/chat/copilot-chat-context.md`, `docs/chat/inline-chat.md`, `docs/chat/review-code-edits.md`, `docs/chat/chat-checkpoints.md`, `docs/chat/chat-artifacts.md`

### extension-api (71 files)
All files under `api/`

### editor (11 files)
All files under `docs/editing/`, `docs/editor/`, `docs/customization/`

### languages (24 files)
All files under `docs/languages/`

### python (17 files)
All files under `docs/python/`

### java (16 files)
All files under `docs/java/`

### containers (17 files)
All files under `docs/containers/`

### devcontainers (9 files)
All files under `docs/devcontainers/`

### remote (10 files)
All files under `docs/remote/`

### sourcecontrol (9 files)
All files under `docs/sourcecontrol/`

### datascience (11 files)
All files under `docs/datascience/`

### intelligentapps (14 files)
All files under `docs/intelligentapps/`

### learn (20 files)
All files under `learn/foundations/` and `learn/customizations/`
