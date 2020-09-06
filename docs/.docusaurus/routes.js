
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
  component: ComponentCreator('/search','9fa'),
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
  component: ComponentCreator('/docs','3d3'),
  
  routes: [
{
  path: '/docs/',
  component: ComponentCreator('/docs/','b73'),
  exact: true,
},
{
  path: '/docs/doc2',
  component: ComponentCreator('/docs/doc2','7d1'),
  exact: true,
},
{
  path: '/docs/doc3',
  component: ComponentCreator('/docs/doc3','6f8'),
  exact: true,
},
{
  path: '/docs/mdx',
  component: ComponentCreator('/docs/mdx','155'),
  exact: true,
},
]
},
{
  path: '*',
  component: ComponentCreator('*')
}
];
