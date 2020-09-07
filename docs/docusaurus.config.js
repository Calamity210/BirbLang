module.exports = {
  title: 'BirbLang',
  tagline: 'Smol Programming Language',
  url: 'https://Calamity210.github.io',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  favicon: 'img/favicon.ico',
  themes: ['@docusaurus/theme-live-codeblock'],
  plugins: [
      [
        '@docusaurus/plugin-content-docs',
        {
          id: 'community',
          path: 'community',
          editUrl: 'https://github.com/Calamity210/BirbLang/edit/master/docs/',
          routeBasePath: 'community',
          sidebarPath: require.resolve('./sidebarsCommunity.js'),
          showLastUpdateAuthor: true,
          showLastUpdateTime: true,
        },
      ],
    ],
  organizationName: 'Calamity210',
  projectName: 'BirbLang',
  themeConfig: {
    colorMode: {
     defaultMode: 'dark',
      disableSwitch: false,
      respectPrefersColorScheme: true,
    },
    announcementBar: {
     id: 'leave_star',
     content: '⭐️ If you like our projects, give it a star on <a target="_blank" rel="noopener noreferrer" href="https://github.com/Calamity210/BirbLang">GitHub</a>! ⭐️',
    },
    navbar: {
      hideOnScroll: true,
      title: 'Birb',
      logo: {
        alt: 'Birb Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          to: 'docs/',
          activeBasePath: 'docs',
          label: 'Docs',
          position: 'left',
        },
        {
          to: 'community/support',
          activeBasePath: 'community',
          label: 'Support',
          position: 'left',
        },
        {
          href: 'https://github.com/Calamity210/BirbLang',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Community',
          items: [
            {
              label: 'Discord',
              href: 'https://discord.gg/9dq6YB2',
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/Calamity210/BirbLang',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} BirbLang, Inc. Built with Docusaurus.`,
    },
    prism: {
     additionalLanguages: ['dart'],
     defaultLanguage: 'dart',
    },
    algolia: {
     apiKey: '7a1c0622f793d186564c3bc2d235068e',
     indexName: 'birb',
     searchParameters: {
      facetFilters: [`version:latest`],
     },
    },
  },
  presets: [
  [
  '@docusaurus/preset-classic',
   {
          docs: {
            path: 'docs',
            sidebarPath: require.resolve('./sidebars.js'),
            editUrl:
              'https://github.com/Calamity210/BirbLang/edit/master/docs/',
            showLastUpdateAuthor: true,
            showLastUpdateTime: true,
            disableVersioning: false,
            lastVersion: 'current',
            onlyIncludeVersions: ['current'],
            versions: {
              current: {
                label: `Next ('deploy preview')`
              },
            },
          },
          theme: {
           customCss: require.resolve('./src/css/custom.css'),
          },
        },
    ],
  ],
};
