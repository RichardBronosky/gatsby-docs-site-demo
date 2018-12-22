#!/bin/bash -eux

gatsby new docs-site
cd docs-site
npm install --save prismjs
npm install --save gatsby-transformer-remark gatsby-remark-prismjs gatsby-remark-copy-linked-files gatsby-remark-images gatsby-source-filesystem

patch <<'EOF'
--- gatsby-config.js.orig	2018-12-22 00:32:05.000000000 -0500
+++ gatsby-config.js	2018-12-22 00:39:26.000000000 -0500
@@ -6,6 +6,8 @@
   },
   plugins: [
     `gatsby-plugin-react-helmet`,
+    `gatsby-transformer-sharp`,
+    `gatsby-plugin-sharp`,
     {
       resolve: `gatsby-source-filesystem`,
       options: {
@@ -13,8 +15,6 @@
         path: `${__dirname}/src/images`,
       },
     },
-    `gatsby-transformer-sharp`,
-    `gatsby-plugin-sharp`,
     {
       resolve: `gatsby-plugin-manifest`,
       options: {
@@ -27,6 +27,29 @@
         icon: `src/images/gatsby-icon.png`, // This path is relative to the root of the site.
       },
     },
+    {
+      resolve: 'gatsby-transformer-remark',
+      options: {
+        plugins: [
+          'gatsby-remark-prismjs',
+          'gatsby-remark-copy-linked-files',
+          {
+            resolve: `gatsby-remark-images`,
+            options: {
+              maxWidth: 800,
+              linkImagesToOriginal: false
+            },
+          }
+        ]
+      }
+    },
+    {
+      resolve: `gatsby-source-filesystem`,
+      options: {
+        path: `${__dirname}/src/docs`,
+        name: "docs",
+      },
+    },
     // this (optional) plugin enables Progressive Web App + Offline functionality
     // To learn more, visit: https://gatsby.app/offline
     // 'gatsby-plugin-offline',
EOF

cat >> gatsby-node.js <<'EOF'

const path = require('path');
exports.createPages = ({ boundActionCreators, graphql }) => {
  const { createPage } = boundActionCreators;
  const docTemplate = path.resolve(`src/templates/docs-template.js`);
  return graphql(`{
      allMarkdownRemark(
        sort: { order: DESC, fields: [frontmatter___title] }
        limit: 1000
      ) {
        edges {
          node {
            excerpt(pruneLength: 250)
            html
            id
            frontmatter {
              path
              title
            }
          }
        }
      }
    }`)
    .then(result => {
      if (result.errors) {
        return Promise.reject(result.errors);
      }
result.data.allMarkdownRemark.edges
        .forEach(({ node }) => {
          createPage({
            path: node.frontmatter.path,
            component: docTemplate,
            context: {}
          });
        });
    });
}
EOF

mkdir src/docs
mkdir src/templates

cat > src/docs/getting-started.md << 'EOF'
---
path: "/getting-started"
title: "Getting Started"
---
## What's this?
This is our first doc!
EOF

cat > src/docs/about.md << 'EOF'
---
path: "/about"
title: "About us"
---
## What's that?
This is another page.
EOF

cat > src/templates/docs-template.js << 'EOF'
import React, { Component } from 'react';
import Helmet from 'react-helmet';
class Template extends Component {
  render() {
    const { markdownRemark: page } = this.props.data;
    return (
      <div>
        <Helmet title={`Docs | ${page.frontmatter.title}`} />
        <div className="page">
          <header>
            <h1>{page.frontmatter.title}</h1>
            <span>{page.frontmatter.baseline}</span>
          </header>
          <div dangerouslySetInnerHTML={{ __html: page.html }} />
        </div>
      </div>
    );
  }
}
export default Template
export const pageQuery = graphql`
  query DocsByPath($path: String!) {
    markdownRemark(frontmatter: { path: { eq: $path } }) {
      html
      frontmatter {
        path
        title
      }
    }
  }
`
;
EOF

