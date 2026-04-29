import { PHASE_DEVELOPMENT_SERVER } from "next/constants.js";

/** @type {import('next').NextConfig} */
const createNextConfig = (phase) => {
  const isDevelopmentServer = phase === PHASE_DEVELOPMENT_SERVER;
  const basePath = isDevelopmentServer ? "" : "/TodoFocus";

  return {
    distDir: isDevelopmentServer ? ".next-dev" : ".next",
    output: "export",
    images: {
      unoptimized: true,
    },
    trailingSlash: true,
    basePath,
    assetPrefix: basePath ? `${basePath}/` : "",
    env: {
      NEXT_PUBLIC_BASE_PATH: basePath,
    },
  };
};

export default createNextConfig;
