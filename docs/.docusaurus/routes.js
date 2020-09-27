
import React from 'react';
import ComponentCreator from '@docusaurus/ComponentCreator';
export default [
{
  path: '/',
  component: ComponentCreator('/','d7d'),
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
