
import React from 'react';
import ComponentCreator from '@docusaurus/ComponentCreator';
export default [
{
  path: '/',
  component: ComponentCreator('/','d7d'),
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
  component: ComponentCreator('/docs','648'),
  
  routes: [
{
  path: '/docs/',
  component: ComponentCreator('/docs/','9a0'),
  exact: true,
},
{
  path: '/docs/string',
  component: ComponentCreator('/docs/string','51a'),
  exact: true,
},
]
},
{
  path: '*',
  component: ComponentCreator('*')
}
];
