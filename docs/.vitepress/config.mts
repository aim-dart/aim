import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Aim",
  description: "A lightweight, fast web framework for Dart",
  cleanUrls: true,

  // SEO
  head: [
    ['meta', { name: 'keywords', content: 'Dart, web framework, serverside dart, Dart server, Dart backend, Dart HTTP, REST API, middleware, Dart フレームワーク, サーバーサイド Dart, ダート, Webフレームワーク' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:title', content: 'Aim - Lightweight Web Framework for Dart' }],
    ['meta', { property: 'og:description', content: 'A lightweight, fast web framework for Dart. Build modern web applications with simplicity and performance.' }],
    ['meta', { property: 'og:url', content: 'https://aim-dart.dev' }],
    ['meta', { property: 'og:site_name', content: 'Aim Framework' }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { name: 'twitter:title', content: 'Aim - Lightweight Web Framework for Dart' }],
    ['meta', { name: 'twitter:description', content: 'A lightweight, fast web framework for Dart. Build modern web applications with simplicity and performance.' }],
    ['link', { rel: 'canonical', href: 'https://aim-dart.dev' }],
  ],

  // Sitemap
  sitemap: {
    hostname: 'https://aim-dart.dev'
  },

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      {
        text: 'v0.0.6',
        items: [
          { text: 'Changelog', link: 'https://github.com/aim-dart/aim/releases' },
          { text: 'Contributing', link: 'https://github.com/aim-dart/aim/blob/main/CONTRIBUTING.md' }
        ]
      }
    ],

    sidebar: [
      {
        text: 'Getting Started',
        collapsed: false,
        items: [
          { text: 'Installation', link: '/getting-started/installation' },
          { text: 'Quick Start', link: '/getting-started/quick-start' },
          { text: 'CLI Reference', link: '/getting-started/cli-reference' }
        ]
      },
      {
        text: 'Concepts',
        collapsed: false,
        items: [
          { text: 'Routing', link: '/concepts/routing' },
          { text: 'Middleware', link: '/concepts/middleware' },
          { text: 'Context', link: '/concepts/context' },
          { text: 'Request/Response', link: '/concepts/request-response' }
        ]
      },
      {
        text: 'Guides',
        collapsed: false,
        items: [
          { text: 'Testing', link: '/guides/testing' },
          { text: 'Best Practices', link: '/guides/best-practices' },
          { text: 'FAQ', link: '/guides/faq' }
        ]
      },
      {
        text: 'Middleware',
        collapsed: false,
        items: [
          { text: 'Overview', link: '/middleware/' },
          { text: 'CORS', link: '/middleware/cors' },
          { text: 'Cookie', link: '/middleware/cookie' },
          { text: 'Form', link: '/middleware/form' },
          { text: 'Multipart', link: '/middleware/multipart' },
          { text: 'Static Files', link: '/middleware/static' },
          { text: 'Logger', link: '/middleware/logger' },
          { text: 'SSE', link: '/middleware/sse' },
          { text: 'JWT Auth', link: '/middleware/jwt' },
          { text: 'Basic Auth', link: '/middleware/basic-auth' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/aim-dart/aim' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2024-present Aim Contributors'
    },

    editLink: {
      pattern: 'https://github.com/aim-dart/aim/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    },

    search: {
      provider: 'local'
    },
  }
})
