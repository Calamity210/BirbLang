
import React from 'react';
import ComponentCreator from '@docusaurus/ComponentCreator';
export default [
{
  path: '/',
  component: ComponentCreator('/','d7d'),
  exact: true,
},
{
  path: '/__docusaurus/debug',
  component: ComponentCreator('/__docusaurus/debug','3d6'),
  exact: true,
},
{
  path: '/__docusaurus/debug/config',
  component: ComponentCreator('/__docusaurus/debug/config','914'),
  exact: true,
},
{
  path: '/__docusaurus/debug/content',
  component: ComponentCreator('/__docusaurus/debug/content','d12'),
  exact: true,
},
{
  path: '/__docusaurus/debug/globalData',
  component: ComponentCreator('/__docusaurus/debug/globalData','3cf'),
  exact: true,
},
{
  path: '/__docusaurus/debug/metadata',
  component: ComponentCreator('/__docusaurus/debug/metadata','31b'),
  exact: true,
},
{
  path: '/__docusaurus/debug/registry',
  component: ComponentCreator('/__docusaurus/debug/registry','0da'),
  exact: true,
},
{
  path: '/__docusaurus/debug/routes',
  component: ComponentCreator('/__docusaurus/debug/routes','244'),
  exact: true,
},
{
  path: '/search',
  component: ComponentCreator('/search','722'),
  exact: true,
},
{
  path: '/community',
  component: ComponentCreator('/community','ee3'),
  
  routes: [
{
  path: '/community/support',
  component: ComponentCreator('/community/support','361'),
  exact: true,
},
]
},
{
  path: '/docs',
  component: ComponentCreator('/docs','497'),
  
  routes: [
{
  path: '/docs/',
  component: ComponentCreator('/docs/','9a0'),
  exact: true,
},
{
  path: '/docs/contributing',
  component: ComponentCreator('/docs/contributing','024'),
  exact: true,
},
{
  path: '/docs/Core/int',
  component: ComponentCreator('/docs/Core/int','d0a'),
  exact: true,
},
{
  path: '/docs/Core/map',
  component: ComponentCreator('/docs/Core/map','5a1'),
  exact: true,
},
{
  path: '/docs/Core/string',
  component: ComponentCreator('/docs/Core/string','788'),
  exact: true,
},
{
  path: '/docs/walkthrough',
  component: ComponentCreator('/docs/walkthrough','99c'),
  exact: true,
},
]
},
{
  path: '*',
  component: ComponentCreator('*')
}
];
