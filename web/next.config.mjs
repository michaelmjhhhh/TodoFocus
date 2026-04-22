const isProduction = process.env.NODE_ENV === "production";

/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "export",
  images: {
    unoptimized: true,
  },
  trailingSlash: true,
  basePath: isProduction ? "/TodoFocus" : "",
  assetPrefix: isProduction ? "/TodoFocus/" : "",
};

export default nextConfig;
