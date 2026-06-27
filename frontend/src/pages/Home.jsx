
import { ArrowRight, ShieldCheck, Users } from "lucide-react";
import { useNavigate } from "react-router-dom";

import { Button } from "@/components/ui/button";

const Home = () => {
  const navigate = useNavigate();

  return (
    <div className="dashboard-page">
      <header className="flex min-h-20 items-center border-b border-[#2b3139] pl-14 pr-4 sm:px-6 lg:px-8">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.12em] text-[#707a8a]">
            Control center
          </p>
          <h1 className="mt-1 text-lg font-semibold tracking-tight text-white">
            Overview
          </h1>
        </div>
      </header>

      <div className="dashboard-content">
        <section className="border-b border-[#2b3139] pb-8">
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-[#fcd535]">
            Oracle administration
          </p>
          <h2 className="mt-4 max-w-2xl text-3xl font-semibold leading-tight tracking-[-0.3px] text-white sm:text-4xl">
            Identity and access management, without the noise.
          </h2>
          <p className="mt-4 max-w-2xl text-sm leading-6 text-[#929aa5]">
            Manage database accounts, roles, and granular privileges from one
            focused control plane.
          </p>
        </section>

        <section className="mt-8 grid gap-4 md:grid-cols-2">
          <article className="rounded-xl border border-[#2b3139] bg-[#1e2329] p-6">
            <div className="flex size-10 items-center justify-center rounded-md bg-[#2b3139] text-[#fcd535]">
              <Users className="size-5" />
            </div>
            <h3 className="mt-6 text-lg font-semibold text-white">
              User accounts
            </h3>
            <p className="mt-2 text-sm leading-6 text-[#929aa5]">
              Create accounts, update credentials, assign roles, and control
              object-level access.
            </p>
            <Button
              variant="outline"
              className="mt-6"
              onClick={() => navigate("/users")}
            >
              Manage users
              <ArrowRight />
            </Button>
          </article>

          <article className="rounded-xl border border-[#2b3139] bg-[#1e2329] p-6">
            <div className="flex size-10 items-center justify-center rounded-md bg-[#2b3139] text-[#fcd535]">
              <ShieldCheck className="size-5" />
            </div>
            <h3 className="mt-6 text-lg font-semibold text-white">
              Roles and privileges
            </h3>
            <p className="mt-2 text-sm leading-6 text-[#929aa5]">
              Define reusable access policies and manage table, column, and
              system privileges.
            </p>
            <Button
              variant="outline"
              className="mt-6"
              onClick={() => navigate("/roles")}
            >
              Manage roles
              <ArrowRight />
            </Button>
          </article>
        </section>
      </div>
    </div>
  );
}

export default Home
