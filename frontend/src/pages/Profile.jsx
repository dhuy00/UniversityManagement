import { useEffect, useState } from "react";
import { Eye, EyeOff, IdCard, Pencil, ShieldCheck } from "lucide-react";

import { getCurrentProfile } from "@/api/profileApi";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import ProfileContactDialog from "@/components/profile/ProfileContactDialog";
import { Button } from "@/components/ui/button";

const formatDate = (value) =>
  new Intl.DateTimeFormat("en-GB", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(new Date(value));

const formatAllowance = (value) =>
  new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND",
    maximumFractionDigits: 0,
  }).format(value);

const ProfileField = ({ label, value }) => (
  <div className="border-b border-[#2b3139] py-4 last:border-b-0">
    <dt className="text-xs font-semibold uppercase tracking-[0.1em] text-[#707a8a]">
      {label}
    </dt>
    <dd className="mt-1.5 text-sm font-medium text-[#eaecef]">
      {value ?? "—"}
    </dd>
  </div>
);

export default function Profile() {
  const [profile, setProfile] = useState(null);
  const [error, setError] = useState("");
  const [showAllowance, setShowAllowance] = useState(false);
  const [editingContact, setEditingContact] = useState(false);

  useEffect(() => {
    let active = true;

    getCurrentProfile()
      .then((data) => {
        if (active) setProfile(data);
      })
      .catch((requestError) => {
        if (!active) return;
        setError(
          requestError.response?.status === 404
            ? "No profile was found for this Oracle identity."
            : "Unable to load your profile.",
        );
      });

    return () => {
      active = false;
    };
  }, []);

  if (error) {
    return (
      <div className="p-6 lg:p-8">
        <div role="alert" className="rounded-lg border border-[#3f4650] bg-[#1e2329] p-5 text-sm text-[#eaecef]">
          {error}
        </div>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="flex min-h-full items-center justify-center">
        <LoadingSpinner label="Loading profile..." />
      </div>
    );
  }

  const isStudent = profile.identityType === "STUDENT";

  return (
    <div className="dashboard-page">
      <header className="flex min-h-20 items-center border-b border-[#2b3139] pl-14 pr-4 sm:px-6 lg:px-8">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.12em] text-[#707a8a]">
            Personal information
          </p>
          <h1 className="mt-1 text-lg font-semibold tracking-tight text-white">
            My Profile
          </h1>
        </div>
      </header>

      <div className="dashboard-content">
        <section className="flex flex-col gap-5 border-b border-[#2b3139] pb-8 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-5">
            <div className="flex size-14 items-center justify-center rounded-lg bg-[#fcd535] text-[#181a20]">
              <IdCard className="size-7" />
            </div>
            <div>
              <h2 className="text-2xl font-semibold text-white">
                {profile.fullName}
              </h2>
              <div className="mt-2 flex items-center gap-2 text-sm text-[#929aa5]">
                <ShieldCheck className="size-4 text-[#fcd535]" />
                {profile.identityType} · {profile.roleCode ?? profile.programId}
              </div>
            </div>
          </div>
          <Button
            type="button"
            variant="outline"
            onClick={() => setEditingContact(true)}
          >
            <Pencil />
            Edit contact
          </Button>
        </section>

        <section className="mt-8 grid gap-6 lg:grid-cols-2">
          <dl className="rounded-xl border border-[#2b3139] bg-[#1e2329] px-6">
            <ProfileField label="Identifier" value={profile.id} />
            <ProfileField label="Full name" value={profile.fullName} />
            <ProfileField label="Gender" value={profile.gender} />
            <ProfileField
              label="Date of birth"
              value={formatDate(profile.dateOfBirth)}
            />
            <ProfileField label="Phone" value={profile.phone} />
            <ProfileField label="Campus" value={profile.campusId} />
          </dl>

          <dl className="rounded-xl border border-[#2b3139] bg-[#1e2329] px-6">
            {isStudent ? (
              <>
                <ProfileField label="Address" value={profile.address} />
                <ProfileField label="Program" value={profile.programId} />
                <ProfileField label="Major" value={profile.majorId} />
                <ProfileField
                  label="Accumulated credits"
                  value={profile.accumulatedCredits}
                />
                <ProfileField
                  label="Cumulative GPA"
                  value={profile.cumulativeGpa}
                />
              </>
            ) : (
              <>
                <ProfileField label="Role" value={profile.roleCode} />
                <ProfileField
                  label="Unit"
                  value={`${profile.unitName} (${profile.unitId})`}
                />
                <div className="border-b border-[#2b3139] py-4 last:border-b-0">
                  <dt className="text-xs font-semibold uppercase tracking-[0.1em] text-[#707a8a]">
                    Allowance
                  </dt>
                  <dd className="mt-1 flex min-h-9 items-center justify-between gap-3">
                    <span className="text-sm font-medium text-[#eaecef]">
                      {showAllowance
                        ? formatAllowance(profile.allowance)
                        : "••••••••"}
                    </span>
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon-sm"
                      aria-label={showAllowance ? "Hide allowance" : "Show allowance"}
                      onClick={() => setShowAllowance((current) => !current)}
                    >
                      {showAllowance
                        ? <EyeOff className="size-4" />
                        : <Eye className="size-4" />}
                    </Button>
                  </dd>
                </div>
              </>
            )}
          </dl>
        </section>
      </div>
      {editingContact && (
        <ProfileContactDialog
          profile={profile}
          onClose={() => setEditingContact(false)}
          onSaved={(contact) =>
            setProfile((current) => ({
              ...current,
              phone: contact.phone,
              ...(isStudent ? { address: contact.address } : {}),
            }))}
        />
      )}
    </div>
  );
}
