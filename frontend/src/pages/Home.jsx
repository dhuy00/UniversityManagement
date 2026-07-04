
import { Database, IdCard, ShieldCheck } from "lucide-react";

import { getAuthSession } from "@/lib/auth";

const Home = () => {
  const session = getAuthSession();

  return (
    <div className="dashboard-page">
      <header className="flex min-h-20 items-center border-b border-[#2b3139] pl-14 pr-4 sm:px-6 lg:px-8">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.12em] text-[#707a8a]">
            University workspace
          </p>
          <h1 className="mt-1 text-lg font-semibold tracking-tight text-white">
            Overview
          </h1>
        </div>
      </header>

      <div className="dashboard-content">
        <section className="border-b border-[#2b3139] pb-8">
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-[#fcd535]">
            Authenticated Oracle session
          </p>
          <h2 className="mt-4 max-w-2xl text-3xl font-semibold leading-tight tracking-[-0.3px] text-white sm:text-4xl">
            Welcome, {session?.username}.
          </h2>
          <p className="mt-4 max-w-2xl text-sm leading-6 text-[#929aa5]">
            Your data access is evaluated with the Oracle identity and role
            shown below. Row-level restrictions are enforced by database VPD
            policies on every connection.
          </p>
        </section>

        <section className="mt-8 grid gap-4 md:grid-cols-2">
          <article className="rounded-xl border border-[#2b3139] bg-[#1e2329] p-6">
            <div className="flex size-10 items-center justify-center rounded-md bg-[#2b3139] text-[#fcd535]">
              <IdCard className="size-5" />
            </div>
            <h3 className="mt-6 text-lg font-semibold text-white">
              Current identity
            </h3>
            <p className="mt-2 text-sm leading-6 text-[#929aa5]">
              Signed in as <span className="font-semibold text-white">
                {session?.username}
              </span> with identity type{" "}
              <span className="font-semibold text-white">
                {session?.identityType}
              </span>.
            </p>
            <p className="mt-4 text-xs font-semibold uppercase tracking-[0.12em] text-[#fcd535]">
              {session?.roleCode}
            </p>
          </article>

          <article className="rounded-xl border border-[#2b3139] bg-[#1e2329] p-6">
            <div className="flex size-10 items-center justify-center rounded-md bg-[#2b3139] text-[#fcd535]">
              <Database className="size-5" />
            </div>
            <h3 className="mt-6 text-lg font-semibold text-white">
              Database-enforced access
            </h3>
            <p className="mt-2 text-sm leading-6 text-[#929aa5]">
              API requests reconnect as your Oracle account. Role grants,
              object privileges, secure context, and VPD determine the rows and
              operations available to you.
            </p>
            <div className="mt-5 flex items-center gap-2 text-xs text-[#929aa5]">
              <ShieldCheck className="size-4 text-[#fcd535]" />
              User and role administration is isolated from this workspace.
            </div>
          </article>
        </section>
      </div>
    </div>
  );
}

export default Home
