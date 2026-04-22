export const siteConfig = {
  basePath: process.env.NODE_ENV === "production" ? "/TodoFocus" : "",
  siteUrl: "https://michaelmjhhhh.github.io/TodoFocus",
  siteName: "TodoFocus",
};

export function assetPath(path: string): string {
  return `${siteConfig.basePath}${path}`;
}

export function docsAssetPath(path: string): string {
  return `${siteConfig.basePath}/docs${path}`;
}
