import { PHASE_DEVELOPMENT_SERVER } from "next/constants.js";

/** @type {import('next').NextConfig} */
const createNextConfig = (phase) => {
  const basePath = phase === PHASE_DEVELOPMENT_SERVER ? "" : "/TodoFocus";

  return {
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
