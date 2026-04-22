/* eslint-disable @next/next/no-img-element */

const DIRECT_DOWNLOAD_URL =
  "https://github.com/michaelmjhhhh/TodoFocus/releases/latest/download/TodoFocus-macos-universal.zip";

export default function Home() {
  const assetBase = process.env.NODE_ENV === "production" ? "/TodoFocus" : "";

  const productSchema = {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    name: "TodoFocus",
    description:
      "A local-first macOS task app that actually helps you finish things. No cloud, no logins, no nonsense.",
    url: "https://michaelmjhhhh.github.io/TodoFocus",
    applicationCategory: "ProductivityApplication",
    operatingSystem: "macOS 14+",
    offers: {
      "@type": "Offer",
      price: "0",
      priceCurrency: "USD",
    },
    downloadUrl:
      "https://github.com/michaelmjhhhh/TodoFocus/releases/latest/download/TodoFocus-macos-universal.zip",
    softwareVersion: "1.0.8",
    author: {
      "@type": "Person",
      name: "TodoFocus",
    },
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(productSchema) }}
      />
    <main className="flex min-h-screen flex-col items-center selection:bg-terracotta selection:text-paper overflow-x-hidden">
      <header className="w-full max-w-4xl mx-auto px-6 py-12 flex justify-between items-center">
        <div className="flex items-center gap-3">
          <img
            src={`${assetBase}/readme-logo.png`}
            alt="TodoFocus Icon"
            width={40}
            height={40}
            className="rounded-xl shadow-sm"
          />
          <span className="font-sans font-medium tracking-tight text-lg text-ink">
            TodoFocus
          </span>
        </div>
        <nav className="flex items-center gap-6">
          <a
            href={`${assetBase}/docs/quick-start/`}
            className="font-sans text-sm text-ink-light hover:text-ink transition-colors"
          >
            Docs
          </a>
          <a
            href={DIRECT_DOWNLOAD_URL}
            className="font-sans text-sm font-medium bg-ink text-paper px-5 py-2.5 rounded-full hover:bg-terracotta transition-colors duration-300"
          >
            Download for macOS
          </a>
        </nav>
      </header>

      <section className="w-full max-w-3xl mx-auto px-6 py-24 md:py-32 flex flex-col items-center text-center">
        <h1 className="font-serif text-5xl md:text-7xl font-normal leading-[1.1] text-ink mb-8 tracking-tight text-balance">
          Stop collecting tasks. <br />
          <span className="italic text-terracotta">Start finishing them.</span>
        </h1>
        <p className="font-sans text-lg md:text-xl text-ink-light max-w-xl mb-12 leading-relaxed text-balance">
          A local-first macOS task app that actually helps you finish things. No
          cloud, no logins, no nonsense. Just you and your work.
        </p>
        <div className="flex flex-col sm:flex-row items-center gap-4">
          <a
            href={DIRECT_DOWNLOAD_URL}
            className="font-sans text-base font-medium bg-terracotta text-paper px-8 py-4 rounded-full hover:bg-terracotta-hover transition-colors shadow-lg hover:shadow-xl duration-300"
          >
            Download Latest Release
          </a>
          <a
            href="https://github.com/michaelmjhhhh/TodoFocus/releases"
            className="font-sans text-base font-medium bg-transparent text-ink-light border border-ink-lighter/30 px-8 py-4 rounded-full hover:bg-paper-dark hover:text-ink transition-colors duration-300"
          >
            View on GitHub
          </a>
        </div>
        <div className="mt-8 flex items-center gap-4 text-xs font-mono text-ink-lighter uppercase tracking-wider">
          <span>macOS 14+</span>
          <span>&bull;</span>
          <span>Native SwiftUI</span>
          <span>&bull;</span>
          <span>Local SQLite</span>
        </div>
      </section>

      <section className="w-full max-w-5xl mx-auto px-6 mb-32">
        <div className="flex gap-6 overflow-x-auto pb-4 snap-x snap-mandatory scroll-smooth
            [&::-webkit-scrollbar]:h-1.5
            [&::-webkit-scrollbar-track]:bg-ink-lighter/10
            [&::-webkit-scrollbar-thumb]:bg-ink-lighter/30
            [&::-webkit-scrollbar-thumb]:rounded-full">
          {[1, 2, 3, 4, 5].map((n) => (
            <div
              key={n}
              className="flex-shrink-0 w-[480px] md:w-[560px] snap-center"
            >
              <div className="relative rounded-2xl overflow-hidden shadow-2xl border border-ink/5 bg-white p-2">
                <img
                  src={`${assetBase}/screenshot-0${n}.png`}
                  alt={`TodoFocus screenshot ${n}`}
                  className="w-full h-auto rounded-xl"
                />
              </div>
            </div>
          ))}
        </div>
      </section>


      <section className="w-full bg-paper-dark py-24 md:py-32">
        <div className="max-w-2xl mx-auto px-6 text-center">
          <h2 className="font-serif text-3xl md:text-4xl italic text-ink mb-8">
            You don&apos;t need another task manager.
          </h2>
          <div className="font-sans text-lg md:text-xl text-ink-light space-y-6 leading-relaxed">
            <p>You already know what to do. You just... don&apos;t do it.</p>
            <p>
              Tasks pile up. Tabs multiply. Context disappears. Focus breaks.
              And suddenly the day is gone.
            </p>
            <p className="font-medium text-ink pt-4">
              Most productivity tools optimize for organization. <br />
              TodoFocus optimizes for momentum.
            </p>
          </div>
        </div>
      </section>


      <section className="w-full max-w-4xl mx-auto px-6 py-24 md:py-32">
        <h2 className="font-sans text-sm font-bold uppercase tracking-widest text-terracotta mb-16 text-center">
          The Method
        </h2>
        <div className="grid md:grid-cols-3 gap-12 md:gap-8 relative">

          <div className="hidden md:block absolute top-6 left-[15%] right-[15%] h-px bg-ink-lighter/20 -z-10" />


          <div className="flex flex-col items-center text-center">
            <div className="w-12 h-12 bg-paper border border-ink-lighter/30 rounded-full flex items-center justify-center font-serif text-xl italic text-ink mb-6 shadow-sm">
              1
            </div>
            <h3 className="font-serif text-2xl text-ink mb-4">Capture</h3>
            <p className="font-sans text-ink-light leading-relaxed">
              Hit <code className="font-mono text-xs bg-paper-dark px-1.5 py-0.5 rounded">⌘⇧T</code>{" "}
              from anywhere to capture thoughts instantly without switching context.
            </p>
          </div>


          <div className="flex flex-col items-center text-center">
            <div className="w-12 h-12 bg-paper border border-ink-lighter/30 rounded-full flex items-center justify-center font-serif text-xl italic text-ink mb-6 shadow-sm">
              2
            </div>
            <h3 className="font-serif text-2xl text-ink mb-4">Focus</h3>
            <p className="font-sans text-ink-light leading-relaxed">
              Start a Deep Focus session. Block distractions, attach links and
              apps, and commit to the work.
            </p>
          </div>


          <div className="flex flex-col items-center text-center">
            <div className="w-12 h-12 bg-paper border border-ink-lighter/30 rounded-full flex items-center justify-center font-serif text-xl italic text-ink mb-6 shadow-sm">
              3
            </div>
            <h3 className="font-serif text-2xl text-ink mb-4">Finish</h3>
            <p className="font-sans text-ink-light leading-relaxed">
              Use the Daily Review to clean your day. Overdue, Today, Tomorrow,
              Done. A fast, honest reset.
            </p>
          </div>
        </div>
      </section>


      <section className="w-full bg-ink text-paper py-24 md:py-32">
        <div className="max-w-4xl mx-auto px-6">
          <div className="flex flex-col md:flex-row items-center gap-12">
            <div className="md:w-1/2">
              <h2 className="font-serif text-4xl mb-6">Launchpad</h2>
              <p className="font-sans text-paper/80 text-lg leading-relaxed mb-6">
                Tasks are not just text. Attach links, files, and apps to your
                tasks. Then launch everything you need in one click.
              </p>
              <p className="font-sans text-paper/80 text-lg leading-relaxed italic">
                No hunting. No tab archaeology. No &quot;wait, where was that
                again?&quot;
              </p>
            </div>
            <div className="md:w-1/2">
              <div className="rounded-xl overflow-hidden shadow-2xl border border-white/10">
                <img
                  src={`${assetBase}/demo.gif`}
                  alt="TodoFocus Launchpad — launch links, files, and apps from a single task"
                  width={800}
                  height={600}
                  className="w-full h-auto"
                />
              </div>
            </div>
          </div>
        </div>
      </section>


      <section className="w-full max-w-3xl mx-auto px-6 py-24 md:py-32 text-center">
        <h2 className="font-serif text-3xl md:text-4xl text-ink mb-6">
          Your data lives here.
        </h2>
        <p className="font-sans text-lg text-ink-light leading-relaxed mb-8">
          100% local SQLite. No account required. No cloud dependency. JSON
          import/export for portability.
        </p>
        <div className="bg-paper-dark rounded-lg p-6 max-w-xl mx-auto font-mono text-sm text-ink-light text-left overflow-x-auto shadow-inner border border-ink-lighter/20">
          <code>~/Library/Application Support/todofocus/</code>
        </div>
      </section>


      <section className="w-full bg-terracotta text-paper py-24 md:py-32 text-center px-6">
        <h2 className="font-serif text-4xl md:text-6xl mb-8">
          Ready to finish things?
        </h2>
        <a
          href={DIRECT_DOWNLOAD_URL}
          className="inline-block font-sans text-lg font-medium bg-paper text-terracotta px-10 py-5 rounded-full hover:bg-white transition-colors shadow-xl duration-300"
        >
          Download for macOS
        </a>
        <p className="mt-8 font-sans text-paper/80">
          Requires macOS 14+ Sonoma or later.
        </p>
      </section>


      <footer className="w-full border-t border-ink-lighter/20 py-12 px-6">
        <div className="max-w-4xl mx-auto flex flex-col md:flex-row justify-between items-center gap-6">
          <div className="flex items-center gap-3">
            <img
              src={`${assetBase}/readme-logo.png`}
              alt="TodoFocus Icon"
              width={24}
              height={24}
              className="rounded-md opacity-80 grayscale"
            />
            <span className="font-sans text-sm text-ink-light">
              &copy; {new Date().getFullYear()} TodoFocus. Local-first task manager.
            </span>
          </div>
          <div className="flex gap-6 font-sans text-sm text-ink-light">
            <a
              href="https://github.com/michaelmjhhhh/TodoFocus"
              className="hover:text-ink transition-colors"
            >
              GitHub
            </a>
            <a
              href="https://github.com/michaelmjhhhh/TodoFocus/issues"
              className="hover:text-ink transition-colors"
            >
              Feedback
            </a>
          </div>
        </div>
      </footer>
    </main>
    </>
  );
}
