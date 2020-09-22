export default {
  "title": "BirbLang",
  "tagline": "Smol Programming Language",
  "url": "https://birbolang.web.app",
  "baseUrl": "/",
  "onBrokenLinks": "throw",
  "favicon": "img/favicon.ico",
  "themes": [
    "@docusaurus/theme-live-codeblock"
  ],
  "plugins": [
    "C:\\Users\\User\\Projects\\BirbLang\\docs\\node_modules\\@cmfcmf\\docusaurus-search-local\\src\\index.js",
    [
      "@docusaurus/plugin-content-docs",
      {
        "id": "community",
        "path": "community",
        "editUrl": "https://github.com/Calamity210/BirbLang/edit/master/docs/",
        "routeBasePath": "community",
        "sidebarPath": "C:\\Users\\User\\Projects\\BirbLang\\docs\\sidebarsCommunity.js",
        "showLastUpdateAuthor": true,
        "showLastUpdateTime": true
      }
    ]
  ],
  "organizationName": "Calamity210",
  "projectName": "BirbLang",
  "themeConfig": {
    "colorMode": {
      "defaultMode": "dark",
      "disableSwitch": false,
      "respectPrefersColorScheme": true,
      "switchConfig": {
        "darkIcon": "🌜",
        "darkIconStyle": {},
        "lightIcon": "🌞",
        "lightIconStyle": {}
      }
    },
    "announcementBar": {
      "id": "leave_star",
      "content": "⭐️ If you like our projects, give it a star on <a target=\"_blank\" rel=\"noopener noreferrer\" href=\"https://github.com/Calamity210/BirbLang\">GitHub</a>! ⭐️",
      "backgroundColor": "#fff",
      "textColor": "#000",
      "isCloseable": true
    },
    "navbar": {
      "hideOnScroll": true,
      "title": "Birb",
      "logo": {
        "alt": "Birb Logo",
        "src": "img/logo.svg"
      },
      "items": [
        {
          "to": "docs/",
          "activeBasePath": "docs",
          "label": "Docs",
          "position": "left"
        },
        {
          "to": "community/support",
          "activeBasePath": "community",
          "label": "Support",
          "position": "left"
        },
        {
          "href": "https://github.com/Calamity210/BirbLang",
          "label": "GitHub",
          "position": "right"
        }
      ]
    },
    "footer": {
      "style": "dark",
      "links": [
        {
          "title": "Community",
          "items": [
            {
              "label": "Discord",
              "href": "https://discord.gg/9dq6YB2"
            }
          ]
        },
        {
          "title": "More",
          "items": [
            {
              "label": "GitHub",
              "href": "https://github.com/Calamity210/BirbLang"
            }
          ]
        }
      ],
      "copyright": "Copyright © 2020 BirbLang"
    },
    "prism": {
      "additionalLanguages": [
        "dart"
      ],
      "defaultLanguage": "dart"
    }
  },
  "presets": [
    [
      "@docusaurus/preset-classic",
      {
        "docs": {
          "path": "docs",
          "sidebarPath": "C:\\Users\\User\\Projects\\BirbLang\\docs\\sidebars.js",
          "editUrl": "https://github.com/Calamity210/BirbLang/edit/master/docs/",
          "showLastUpdateAuthor": true,
          "showLastUpdateTime": true,
          "disableVersioning": false,
          "lastVersion": "current",
          "onlyIncludeVersions": [
            "current"
          ],
          "versions": {
            "current": {
              "label": "Next ('deploy preview')"
            }
          }
        },
        "theme": {
          "customCss": "C:\\Users\\User\\Projects\\BirbLang\\docs\\src\\css\\custom.css"
        }
      }
    ]
  ],
  "onDuplicateRoutes": "warn",
  "customFields": {}
};