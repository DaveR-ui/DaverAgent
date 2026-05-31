---
description: Guide for using and developing with Storybook in the project.
---

# Storybook in the Project

Storybook is our main tool for developing UI components in isolation. Follow these guides to work with it.

## Main Commands

- `npm run storybook`: Starts the development server at `http://localhost:6006`.
- `npm run build-storybook`: Generates a static version of Storybook for deployment.

## Story Structure

Stories should be placed alongside the component they document, with the `.stories.ts` extension.

### Basic Example

```typescript
import type { Meta, StoryObj } from '@storybook/angular';
import { MiComponente } from './mi-componente';

const meta: Meta<MiComponente> = {
  title: 'Category/MiComponente',
  component: MiComponente,
  tags: ['autodocs'], // Enables the automatic documentation tab
  argTypes: {
    // Define manual controls here if needed
    color: { control: 'color' }
  }
};

export default meta;
type Story = StoryObj<MiComponente>;

export const Default: Story = {
  args: {
    parametro: 'valor'
  }
};
```

## Best Practices

1. **Automatic Documentation (`autodocs`)**: Always include the `autodocs` tag in the meta object.
2. **Containers**: If the component needs a specific background (e.g., white or transparent components), use the `render` function to wrap it in a div with appropriate styles.
3. **Modern Providers**: For components that use Signals or animations, make sure to include `provideAnimations()` and other required providers using `applicationConfig` in the `decorators`.
4. **Interactivity**: Use `argTypes` so other developers can test different component states without modifying the code.

## Troubleshooting

### Component missing fonts or icons
- Check `.storybook/preview-head.html`. Links to **Roboto** and **Material Icons** have been added to match the app's `index.html`.
- If you add new external fonts, make sure to include them there as well.

### Component doesn't look right or is missing styles
- Verify that the component is using global CSS variables.
- Storybook is configured to load `src/styles.scss`, make sure the component uses those tokens.
- If using Angular Material, ensure the required module is in the `imports` of `moduleMetadata` within the story.
- `provideAnimations()` has been configured globally in `.storybook/preview.ts` so Material components (and others) have their animations active.

### Dependency errors on install
- If you install new addons, use `--legacy-peer-deps` if you encounter version conflicts with Angular 21.
