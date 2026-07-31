import { forwardRef } from "react";

const Textarea = forwardRef(
  ({ className, ...props }, ref) => {
    return (
      <textarea
        ref={ref}
        className={
          className
            ? className
            : "flex min-h-[80px] w-full rounded-md border border-[#2b3139] bg-[#0b0e11] px-3 py-2 text-[13px] text-white placeholder:text-[#707a8a] focus:border-[#fcd535] focus:outline-none disabled:cursor-not-allowed disabled:opacity-50"
        }
        {...props}
      />
    );
  },
);

Textarea.displayName = "Textarea";

export { Textarea };
