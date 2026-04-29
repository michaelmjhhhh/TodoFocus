/* eslint-disable @next/next/no-img-element */

const DIRECT_DOWNLOAD_URL =
  "https://github.com/michaelmjhhhh/TodoFocus/releases/latest/download/TodoFocus-macos-universal.zip";

const RELEASES_URL = "https://github.com/michaelmjhhhh/TodoFocus/releases";
const REPO_URL = "https://github.com/michaelmjhhhh/TodoFocus";

const workflowSteps = [
  {
    kicker: "01",
    title: "Capture",
    copy: "Open Quick Capture from anywhere and send the thought to Inbox or the active focus task.",
  },
  {
    kicker: "02",
    title: "Choose",
    copy: "Search, filter, and pick from the native task list before the day gets crowded.",
  },
  {
    kicker: "03",
    title: "Launch",
    copy: "Open the links, files, and apps attached to the task in one motion.",
  },
  {
    kicker: "04",
    title: "Review",
    copy: "Reset overdue work and tomorrow's plan before the day gets noisy.",
  },
];

const featureSpotlights = [
  {
    eyebrow: "Quick Capture",
    title: "Capture ideas without leaving the work.",
    copy: "The Quick Capture panel makes a thought fast to enter, with voice capture available and routing shown clearly when no Deep Focus session is active.",
    image: "screenshot-03.png",
    alt: "TodoFocus Quick Capture panel",
    stat: "Command Shift T",
  },
  {
    eyebrow: "Deep Focus",
    title: "Keep focus state close to the menu bar.",
    copy: "The Deep Focus status panel shows whether a session is active, how many apps are blocked, and gives quick access back into TodoFocus.",
    image: "screenshot-05.png",
    alt: "TodoFocus Deep Focus status panel",
    stat: "Blocked apps + session state",
  },
  {
    eyebrow: "Daily Review",
    title: "Review the day before it becomes clutter.",
    copy: "The Daily Review board separates overdue, today, tomorrow, later, and completed work so you can move tasks with a clear sense of status.",
    image: "screenshot-01.png",
    alt: "TodoFocus Daily Review board",
    stat: "Open, today, tomorrow, done",
  },
];

const galleryItems = [
  {
    image: "screenshot-01.png",
    title: "Daily Review board",
    copy: "A full-screen review surface for open, overdue, today, tomorrow, later, and completed work.",
    className: "lg:col-span-8",
  },
  {
    image: "screenshot-04.png",
    title: "Menu bar review preview",
    copy: "A compact Daily Review preview shows counts and the tasks needing attention next.",
    className: "lg:col-span-4",
  },
  {
    image: "screenshot-02.png",
    title: "All Tasks workspace",
    copy: "Search, time filters, active tasks, completed visibility, and shortcut hints stay in one calm view.",
    className: "lg:col-span-5",
  },
  {
    image: "screenshot-03.png",
    title: "Quick Capture panel",
    copy: "A focused capture window keeps adding a task lightweight, including microphone capture.",
    className: "lg:col-span-7",
  },
];

const trustFacts = [
  "macOS 14+",
  "Native SwiftUI",
  "Local SQLite",
  "No account",
  "JSON import/export",
];

export default function Home() {
  const assetBase = process.env.NEXT_PUBLIC_BASE_PATH ?? "";

  const productSchema = {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    name: "TodoFocus",
    description:
      "A native, local-first macOS task app for capturing work, launching task context, staying in Deep Focus, and reviewing the day.",
    url: "https://michaelmjhhhh.github.io/TodoFocus",
    applicationCategory: "ProductivityApplication",
    operatingSystem: "macOS 14+",
    offers: {
      "@type": "Offer",
      price: "0",
      priceCurrency: "USD",
    },
    downloadUrl: DIRECT_DOWNLOAD_URL,
    softwareVersion: "1.0.9",
    author: {
      "@type": "Person",
      name: "TodoFocus",
    },
  };

  const imagePath = (name: string) => `${assetBase}/${name}`;

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(productSchema) }}
      />
      <main className="min-h-screen overflow-x-hidden bg-[#f5f0e8] text-[#191715] selection:bg-terracotta selection:text-paper">
        <section className="relative min-h-[88vh] w-full overflow-hidden bg-[#151311] text-paper">
          <div className="absolute inset-0">
            <img
              src={imagePath("screenshot-01.png")}
              alt="TodoFocus macOS app interface"
              className="h-full w-full object-cover opacity-42 saturate-[0.82]"
            />
            <div className="absolute inset-0 bg-[linear-gradient(90deg,rgba(21,19,17,0.98)_0%,rgba(21,19,17,0.86)_34%,rgba(21,19,17,0.42)_72%,rgba(21,19,17,0.66)_100%)]" />
            <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(21,19,17,0.2)_0%,rgba(21,19,17,0.18)_66%,#f5f0e8_100%)]" />
          </div>

          <header className="relative z-10 mx-auto flex w-full max-w-7xl items-center justify-between px-5 py-5 sm:px-8 lg:px-10">
            <a href="#top" className="flex items-center gap-3 rounded-full focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-terracotta">
              <img
                src={imagePath("readme-logo.png")}
                alt="TodoFocus icon"
                width={42}
                height={42}
                className="rounded-xl shadow-[0_12px_30px_rgba(0,0,0,0.28)]"
              />
              <span className="font-sans text-lg font-semibold tracking-tight">
                TodoFocus
              </span>
            </a>
            <nav className="hidden items-center gap-7 text-sm text-paper/72 md:flex">
              <a href="#workflow" className="transition hover:text-paper">
                Workflow
              </a>
              <a href="#features" className="transition hover:text-paper">
                Features
              </a>
              <a href="#gallery" className="transition hover:text-paper">
                Screenshots
              </a>
            </nav>
            <a
              href={DIRECT_DOWNLOAD_URL}
              className="rounded-full bg-paper px-5 py-2.5 text-sm font-semibold text-[#151311] shadow-[0_14px_36px_rgba(0,0,0,0.25)] transition hover:bg-white focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-terracotta"
            >
              Download
            </a>
          </header>

          <div id="top" className="relative z-10 mx-auto grid w-full max-w-7xl gap-12 px-5 pb-20 pt-20 sm:px-8 md:pb-24 md:pt-28 lg:grid-cols-[0.9fr_1.1fr] lg:px-10">
            <div className="flex max-w-2xl flex-col justify-center">
              <div className="mb-6 flex flex-wrap items-center gap-2 text-xs font-semibold uppercase tracking-[0.24em] text-paper/62">
                <span className="rounded-full border border-paper/15 bg-paper/8 px-3 py-1.5">
                  Native macOS
                </span>
                <span className="rounded-full border border-paper/15 bg-paper/8 px-3 py-1.5">
                  Local-first
                </span>
              </div>
              <h1 className="max-w-4xl font-serif text-5xl font-normal leading-[0.97] tracking-tight text-balance sm:text-6xl lg:text-7xl">
                A task app for actually finishing the day.
              </h1>
              <p className="mt-7 max-w-xl text-lg leading-8 text-paper/76 sm:text-xl">
                TodoFocus turns capture, planning, task context, focus sessions,
                and daily review into one native macOS workflow. No account. No
                cloud dependency. No productivity theater.
              </p>
              <div className="mt-9 flex flex-col gap-3 sm:flex-row">
                <a
                  href={DIRECT_DOWNLOAD_URL}
                  className="inline-flex items-center justify-center rounded-full bg-terracotta px-7 py-4 text-base font-semibold text-paper shadow-[0_18px_48px_rgba(196,104,73,0.32)] transition hover:bg-terracotta-hover focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-paper"
                >
                  Download for macOS
                </a>
                <a
                  href={RELEASES_URL}
                  className="inline-flex items-center justify-center rounded-full border border-paper/18 bg-paper/8 px-7 py-4 text-base font-semibold text-paper transition hover:border-paper/36 hover:bg-paper/12 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-paper"
                >
                  View releases
                </a>
              </div>
              <div className="mt-8 flex flex-wrap gap-x-4 gap-y-2 text-sm text-paper/58">
                {trustFacts.slice(0, 4).map((fact) => (
                  <span key={fact} className="flex items-center gap-2">
                    <span className="h-1.5 w-1.5 rounded-full bg-terracotta" />
                    {fact}
                  </span>
                ))}
              </div>
            </div>

            <div className="relative hidden min-h-[520px] items-center lg:flex">
              <div className="absolute -right-16 top-10 h-[460px] w-[660px] rounded-[2rem] border border-paper/10 bg-[#22201d]/82 shadow-[0_44px_110px_rgba(0,0,0,0.42)] backdrop-blur">
                <div className="flex h-9 items-center gap-2 border-b border-paper/10 px-4">
                  <span className="h-3 w-3 rounded-full bg-[#ff6159]" />
                  <span className="h-3 w-3 rounded-full bg-[#ffbd2e]" />
                  <span className="h-3 w-3 rounded-full bg-[#28c840]" />
                </div>
                <img
                  src={imagePath("screenshot-02.png")}
                  alt="TodoFocus All Tasks workspace"
                  className="h-[421px] w-full rounded-b-[1.7rem] object-cover object-left-top"
                />
              </div>
              <div className="absolute bottom-12 left-8 w-[330px] rounded-3xl border border-paper/12 bg-[#191715]/92 p-4 shadow-[0_32px_80px_rgba(0,0,0,0.36)] backdrop-blur">
                <img
                  src={imagePath("screenshot-03.png")}
                  alt="TodoFocus Quick Capture panel"
                  className="aspect-[1.16] w-full rounded-2xl object-cover"
                />
                <div className="mt-4 flex items-center justify-between text-sm">
                  <span className="font-medium text-paper">Quick Capture</span>
                  <span className="font-mono text-paper/52">Command Shift T</span>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="workflow" className="relative mx-auto -mt-10 w-full max-w-7xl px-5 sm:px-8 lg:px-10">
          <div className="grid gap-px overflow-hidden rounded-[1.75rem] border border-[#2b2722]/10 bg-[#2b2722]/10 shadow-[0_30px_90px_rgba(43,39,34,0.16)] md:grid-cols-4">
            {workflowSteps.map((step) => (
              <div key={step.title} className="bg-[#fbf8f1] p-6 md:p-7">
                <div className="font-mono text-xs font-semibold text-terracotta">
                  {step.kicker}
                </div>
                <h2 className="mt-5 font-serif text-3xl text-[#1b1815]">
                  {step.title}
                </h2>
                <p className="mt-3 text-sm leading-6 text-[#625a50]">
                  {step.copy}
                </p>
              </div>
            ))}
          </div>
        </section>

        <section className="mx-auto w-full max-w-7xl px-5 py-24 sm:px-8 md:py-32 lg:px-10">
          <div className="grid gap-12 lg:grid-cols-[0.8fr_1.2fr] lg:items-end">
            <div>
              <p className="font-mono text-sm font-semibold uppercase tracking-[0.24em] text-terracotta">
                Product clarity
              </p>
              <h2 className="mt-4 max-w-2xl font-serif text-4xl leading-tight tracking-tight text-[#1b1815] sm:text-5xl">
                Every major feature maps to a moment in the workday.
              </h2>
            </div>
            <p className="max-w-2xl text-lg leading-8 text-[#625a50]">
              TodoFocus is not a storage cabinet for obligations. It is a
              compact loop: catch the thought, pick the right task, launch its
              context, protect attention, and review what changed.
            </p>
          </div>
        </section>

        <section id="features" className="w-full bg-[#191715] py-24 text-paper md:py-32">
          <div className="mx-auto w-full max-w-7xl px-5 sm:px-8 lg:px-10">
            <div className="grid gap-6">
              {featureSpotlights.map((feature, index) => (
                <article
                  key={feature.title}
                  className="grid overflow-hidden rounded-[1.75rem] border border-paper/10 bg-[#211e1a] shadow-[0_28px_90px_rgba(0,0,0,0.28)] lg:grid-cols-2"
                >
                  <div className={`flex flex-col justify-between p-7 sm:p-10 ${index % 2 === 1 ? "lg:order-2" : ""}`}>
                    <div>
                      <p className="font-mono text-xs font-semibold uppercase tracking-[0.24em] text-terracotta">
                        {feature.eyebrow}
                      </p>
                      <h3 className="mt-5 max-w-lg font-serif text-4xl leading-tight tracking-tight sm:text-5xl">
                        {feature.title}
                      </h3>
                      <p className="mt-5 max-w-xl text-lg leading-8 text-paper/68">
                        {feature.copy}
                      </p>
                    </div>
                    <div className="mt-10 inline-flex w-fit rounded-full border border-paper/12 bg-paper/8 px-4 py-2 font-mono text-xs uppercase tracking-[0.18em] text-paper/66">
                      {feature.stat}
                    </div>
                  </div>
                  <div className="bg-[#141210] p-3 sm:p-5">
                    <img
                      src={imagePath(feature.image)}
                      alt={feature.alt}
                      className="h-full min-h-[320px] w-full rounded-[1.25rem] object-cover object-left-top"
                    />
                  </div>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className="w-full bg-[#f5f0e8] py-24 md:py-32">
          <div className="mx-auto grid w-full max-w-7xl gap-10 px-5 sm:px-8 lg:grid-cols-[0.75fr_1.25fr] lg:px-10">
            <div className="lg:pt-12">
              <p className="font-mono text-sm font-semibold uppercase tracking-[0.24em] text-terracotta">
                Context Launchpad
              </p>
              <h2 className="mt-4 font-serif text-4xl leading-tight tracking-tight text-[#1b1815] sm:text-5xl">
                Tasks can carry the tools needed to finish them.
              </h2>
              <p className="mt-6 text-lg leading-8 text-[#625a50]">
                Add URLs, files, and apps to a task, then launch the whole
                workspace when you are ready. The task becomes the doorway back
                into the actual work.
              </p>
            </div>
            <div className="overflow-hidden rounded-[1.75rem] border border-[#2b2722]/10 bg-[#151311] p-3 shadow-[0_34px_100px_rgba(43,39,34,0.22)]">
              <img
                src={imagePath("demo.gif")}
                alt="TodoFocus Launchpad opening task resources"
                className="w-full rounded-[1.25rem] object-cover"
              />
            </div>
          </div>
        </section>

        <section id="gallery" className="w-full bg-[#ede7dc] py-24 md:py-32">
          <div className="mx-auto w-full max-w-7xl px-5 sm:px-8 lg:px-10">
            <div className="mb-12 flex flex-col justify-between gap-6 lg:flex-row lg:items-end">
              <div>
                <p className="font-mono text-sm font-semibold uppercase tracking-[0.24em] text-terracotta">
                  Screenshot gallery
                </p>
                <h2 className="mt-4 max-w-2xl font-serif text-4xl leading-tight tracking-tight text-[#1b1815] sm:text-5xl">
                  A cleaner look at the surfaces you will use every day.
                </h2>
              </div>
              <p className="max-w-md text-base leading-7 text-[#625a50]">
                Each view is organized around action: what needs attention, what
                context belongs to the task, and what can be finished now.
              </p>
            </div>

            <div className="grid gap-5 lg:grid-cols-12">
              {galleryItems.map((item) => (
                <figure
                  key={item.title}
                  className={`${item.className} overflow-hidden rounded-[1.5rem] border border-[#2b2722]/10 bg-[#fbf8f1] shadow-[0_26px_80px_rgba(43,39,34,0.14)]`}
                >
                  <div className="bg-[#161411] p-2.5">
                    <img
                      src={imagePath(item.image)}
                      alt={`${item.title} screenshot`}
                      className="h-[330px] w-full rounded-[1rem] object-cover object-left-top md:h-[430px]"
                    />
                  </div>
                  <figcaption className="p-5 sm:p-6">
                    <h3 className="font-serif text-2xl text-[#1b1815]">
                      {item.title}
                    </h3>
                    <p className="mt-2 text-sm leading-6 text-[#625a50]">
                      {item.copy}
                    </p>
                  </figcaption>
                </figure>
              ))}
            </div>
          </div>
        </section>

        <section className="w-full bg-[#191715] py-24 text-paper md:py-32">
          <div className="mx-auto grid w-full max-w-7xl gap-10 px-5 sm:px-8 lg:grid-cols-[1fr_1fr] lg:items-center lg:px-10">
            <div>
              <p className="font-mono text-sm font-semibold uppercase tracking-[0.24em] text-terracotta">
                Local-first by default
              </p>
              <h2 className="mt-4 font-serif text-4xl leading-tight tracking-tight sm:text-5xl">
                Your task system lives on your Mac.
              </h2>
              <p className="mt-6 text-lg leading-8 text-paper/68">
                TodoFocus stores data in local SQLite, works without an account,
                and keeps portability available through JSON import and export.
              </p>
            </div>
            <div className="rounded-[1.5rem] border border-paper/10 bg-paper/6 p-6 shadow-[0_28px_90px_rgba(0,0,0,0.24)]">
              <div className="mb-5 flex flex-wrap gap-2">
                {trustFacts.map((fact) => (
                  <span
                    key={fact}
                    className="rounded-full border border-paper/10 bg-paper/8 px-3 py-1.5 text-sm text-paper/72"
                  >
                    {fact}
                  </span>
                ))}
              </div>
              <div className="overflow-x-auto rounded-2xl border border-paper/10 bg-[#11100e] p-5 font-mono text-sm text-paper/72">
                ~/Library/Application Support/todofocus/
              </div>
            </div>
          </div>
        </section>

        <section className="w-full bg-terracotta px-5 py-20 text-center text-paper sm:px-8 md:py-28">
          <h2 className="mx-auto max-w-3xl font-serif text-4xl leading-tight tracking-tight sm:text-6xl">
            Start with the next task, not another system.
          </h2>
          <p className="mx-auto mt-5 max-w-xl text-lg leading-8 text-paper/78">
            Latest release: v1.0.9. Requires macOS 14 Sonoma or later.
          </p>
          <div className="mt-9 flex flex-col items-center justify-center gap-3 sm:flex-row">
            <a
              href={DIRECT_DOWNLOAD_URL}
              className="inline-flex rounded-full bg-paper px-8 py-4 text-base font-semibold text-terracotta shadow-[0_18px_48px_rgba(90,36,20,0.24)] transition hover:bg-white focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-paper"
            >
              Download TodoFocus
            </a>
            <a
              href={REPO_URL}
              className="inline-flex rounded-full border border-paper/28 px-8 py-4 text-base font-semibold text-paper transition hover:bg-paper/10 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-paper"
            >
              View source
            </a>
          </div>
        </section>

        <footer className="w-full border-t border-[#2b2722]/10 bg-[#f5f0e8] px-5 py-10 sm:px-8">
          <div className="mx-auto flex w-full max-w-7xl flex-col gap-6 md:flex-row md:items-center md:justify-between">
            <div className="flex items-center gap-3">
              <img
                src={imagePath("readme-logo.png")}
                alt="TodoFocus icon"
                width={28}
                height={28}
                className="rounded-lg"
              />
              <span className="text-sm text-[#625a50]">
                TodoFocus. Native, local-first task focus for macOS.
              </span>
            </div>
            <div className="flex gap-6 text-sm text-[#625a50]">
              <a href={REPO_URL} className="transition hover:text-[#1b1815]">
                GitHub
              </a>
              <a
                href="https://github.com/michaelmjhhhh/TodoFocus/issues"
                className="transition hover:text-[#1b1815]"
              >
                Feedback
              </a>
              <a href={RELEASES_URL} className="transition hover:text-[#1b1815]">
                Releases
              </a>
            </div>
          </div>
        </footer>
      </main>
    </>
  );
}
