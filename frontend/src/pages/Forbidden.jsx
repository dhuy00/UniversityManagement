import { ArrowLeft, ShieldX } from "lucide-react";
import { useLocation, useNavigate } from "react-router-dom";

import { Button } from "@/components/ui/button";

export default function Forbidden() {
  const location = useLocation();
  const navigate = useNavigate();
  const attemptedPath = location.state?.attemptedPath;

  return (
    <div className="flex min-h-full items-center justify-center p-6">
      <section className="w-full max-w-xl rounded-xl border border-[#2b3139] bg-[#1e2329] p-8">
        <div className="flex size-12 items-center justify-center rounded-md bg-[#2b3139] text-[#fcd535]">
          <ShieldX className="size-6" />
        </div>
        <p className="mt-6 text-xs font-semibold uppercase tracking-[0.14em] text-[#fcd535]">
          Access denied
        </p>
        <h1 className="mt-3 text-3xl font-semibold tracking-tight text-white">
          You do not have access
        </h1>
        <p className="mt-4 text-sm leading-6 text-[#929aa5]">
          Your authenticated role does not have permission to open this area.
          Data access is enforced again by the API and Oracle database.
        </p>
        {attemptedPath && (
          <p className="mt-3 text-xs text-[#707a8a]">
            Blocked path: {attemptedPath}
          </p>
        )}
        <Button className="mt-7" onClick={() => navigate("/", { replace: true })}>
          <ArrowLeft />
          Return to overview
        </Button>
      </section>
    </div>
  );
}
