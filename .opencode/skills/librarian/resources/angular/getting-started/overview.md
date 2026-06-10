<!-- @INDEX
domain: getting-started
type: overview
level: beginner
topics: setup,installation,cli,prerequisites
keywords: angular,setup,install,cli,quickstart
-->



<div style="margin: 2em">
  Maintained by a dedicated team at Google, Angular provides a broad suite of tools, APIs, and
  libraries to simplify and streamline your development workflow. Angular gives you
  a solid platform on which to build fast, reliable applications that scale with both the size of
  your team and the size of your codebase. Angular.dev is the official home for Angular documentation.
</div>

<docs-nav-card title="Want to see some code?" iconImgSrc="adev/src/assets/icons/star.svg">
  <docs-nav-link title="Essentials" iconName="docs" href="essentials" iconImgSrc="adev/src/assets/icons/docs.svg">
    An overview of what it's like to use Angular
  </docs-nav-link>
  <docs-nav-link title="Tutorials" iconName="code"  href="tutorials" iconImgSrc="adev/src/assets/icons/tutorials.svg">
    Step-by-step instructions in your browser
  </docs-nav-link>
</docs-nav-card>
Get started with Angular quickly with online starters or locally with your terminal.

## Play Online

If you just want to play around with Angular in your browser without setting up a project, you can use our online sandbox:
## Set up a new project locally

If you're starting a new project, you'll most likely want to create a local project so that you can use tooling such as Git.

### Prerequisites

- **Node.js** - [v20.19.0 or newer](/reference/versions)
- **Text editor** - We recommend [Visual Studio Code](https://code.visualstudio.com/)
- **Terminal** - Required for running [Angular CLI](/tools/cli) commands
- **Development Tool** - To improve your development workflow, we recommend the [Angular Language Service](/tools/language-service)

### Instructions

The following guide will walk you through setting up a local Angular project.

#### Install Angular CLI

Open a terminal (if you're using [Visual Studio Code](https://code.visualstudio.com/), you can open an [integrated terminal](https://code.visualstudio.com/docs/editor/integrated-terminal)) and run the following command:

```shell
// npm
npm install -g @angular/cli
```
```shell
// pnpm
pnpm install -g @angular/cli
```
```shell
// yarn
yarn global add @angular/cli
```
```shell
// bun
bun install -g @angular/cli
```
If you are having issues running this command in Windows or Unix, check out the [CLI docs](/tools/cli/setup-local#install-the-angular-cli) for more info.

#### Create a new project

In your terminal, run the CLI command [`ng new`](cli/new) with the desired project name. In the following examples, we'll be using the example project name of `my-first-angular-app`.

```shell
ng new <project-name>
```

You will be presented with some configuration options for your project. Use the arrow and enter keys to navigate and select which options you desire.

If you don't have any preferences, just hit the enter key to take the default options and continue with the setup.

After you select the configuration options and the CLI runs through the setup, you should see the following message:

```text
✔ Packages installed successfully.
    Successfully initialized git.
```

At this point, you're now ready to run your project locally!

#### Running your new project locally

In your terminal, switch to your new Angular project.

```shell
cd my-first-angular-app
```

All of your dependencies should be installed at this point (which you can verify by checking for the existence of a `node_modules` folder in your project), so you can start your project by running the command:

```shell
npm start
```

If everything is successful, you should see a similar confirmation message in your terminal:

```text
Watch mode enabled. Watching for file changes...
NOTE: Raw file sizes do not reflect development server per-request transformations.
  ➜  Local:   http://localhost:4200/
  ➜  press h + enter to show help
```

And now you can visit the path in `Local` (e.g., `http://localhost:4200`) to see your application. Happy coding! 🎉

### Using AI for Development

To get started with building in your preferred AI powered IDE, [check out Angular prompt rules and best practices](/ai/develop-with-ai).

## Next steps

Now that you've created your Angular project, you can learn more about Angular in our [Essentials guide](/essentials) or choose a topic in our in-depth guides!
