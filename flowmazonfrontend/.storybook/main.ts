import type { StorybookConfig } from '@storybook/nextjs';

const config: StorybookConfig = {
  stories: ['../src/**/*.mdx', '../src/**/*.stories.@(js|jsx|mjs|ts|tsx)'],

  addons: [
    '@storybook/addon-essentials',
    //'@chromatic-com/storybook',
    '@storybook/addon-storysource',
    '@storybook/addon-a11y',
    '@storybook/addon-interactions',
    '@storybook/addon-coverage',
  ],

  docs: {
    defaultName: 'Documentation',
    autodocs: true,
  },

  framework: {
    name: '@storybook/nextjs',
    options: {},
  },

  staticDirs: ['..\\public'],

  core: {
    disableTelemetry: true, // 👈 Disables telemetry
  },

  typescript: {
    reactDocgen: 'react-docgen-typescript',
  },
};
export default config;
