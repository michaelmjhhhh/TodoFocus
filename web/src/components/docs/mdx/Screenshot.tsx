import { assetPath } from "@/lib/site";

interface ScreenshotProps {
  src: string;
  alt: string;
  caption?: string;
}

export function Screenshot({ src, alt, caption }: ScreenshotProps) {
  return (
    <figure className="my-8">
      <div className="rounded-2xl overflow-hidden shadow-2xl border border-ink/5 bg-white">
        <img
          src={assetPath(src)}
          alt={alt}
          className="w-full h-auto rounded-xl"
        />
      </div>
      {caption && (
        <figcaption className="mt-3 text-center font-sans text-sm text-ink-light italic">
          {caption}
        </figcaption>
      )}
    </figure>
  );
}
