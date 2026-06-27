import { LoaderCircle } from "lucide-react";

import { cn } from "@/lib/utils";

const LoadingSpinner = ({
  label = "Loading...",
  className,
  iconClassName,
  showLabel = true,
}) => (
  <span
    role="status"
    aria-live="polite"
    className={cn("inline-flex items-center justify-center gap-2", className)}
  >
    <LoaderCircle
      aria-hidden="true"
      className={cn("size-4 animate-spin", iconClassName)}
    />
    {showLabel && <span>{label}</span>}
    {!showLabel && <span className="sr-only">{label}</span>}
  </span>
);

export default LoadingSpinner;
