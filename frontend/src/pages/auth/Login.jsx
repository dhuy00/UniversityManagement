import { useState, useEffect } from "react";
import { useLocation, useNavigate } from "react-router-dom";

import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Field, FieldGroup, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import { Database, LockKeyhole, ShieldCheck } from "lucide-react";
import { login } from "@/api/authApi";
import {
  getAuthSession,
  saveAuthSession,
} from "@/lib/auth";

const Login = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const redirectTo = location.state?.from?.pathname || "/";

  const [formData, setFormData] = useState({
    username: "",
    password: "",
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleChange = (e) => {
    if (error) setError("");
    setFormData((prev) => ({
      ...prev,
      [e.target.name]: e.target.value,
    }));
  };

  useEffect(() => {
    if (getAuthSession()) {
      navigate(redirectTo, { replace: true });
    }
  }, [navigate, redirectTo]);

  const handleSubmit = async (e) => {
    e.preventDefault();

    setError("");

    if (!formData.username.trim()) {
      setError("Username is required");
      return;
    }

    if (!formData.password.trim()) {
      setError("Password is required");
      return;
    }

    try {
      setLoading(true);

      const result = await login({
        username: formData.username.trim(),
        password: formData.password,
      });
      saveAuthSession(result);
      navigate(redirectTo, { replace: true });
    } catch (err) {
      setError(
        err.response?.data?.message ||
          "Unable to sign in. Check the API and Oracle database.",
      );
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="grid min-h-screen bg-[#0b0e11] lg:grid-cols-[1.1fr_0.9fr]">
      <section className="hidden border-r border-[#2b3139] p-12 lg:flex lg:flex-col lg:justify-between xl:p-16">
        <div className="flex items-center gap-3">
          <div className="flex size-10 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
            <Database className="size-6" />
          </div>
          <div>
            <p className="text-lg font-semibold text-white">DB Control</p>
            <p className="text-xs font-medium uppercase tracking-[0.14em] text-[#707a8a]">
              Oracle Administration
            </p>
          </div>
        </div>

        <div className="max-w-xl">
          <p className="mb-5 text-xs font-semibold uppercase tracking-[0.14em] text-[#fcd535]">
            Secure database operations
          </p>
          <h1 className="text-4xl font-semibold leading-[1.15] tracking-[-0.3px] text-white xl:text-5xl">
            Manage identities and access with confidence.
          </h1>
          <p className="mt-6 max-w-lg text-base leading-7 text-[#929aa5]">
            A focused control plane for Oracle users, roles, and granular
            privileges.
          </p>
        </div>

        <div className="flex items-center gap-6 text-sm text-[#707a8a]">
          <span className="flex items-center gap-2">
            <ShieldCheck className="size-4 text-[#fcd535]" />
            Access controlled
          </span>
          <span className="flex items-center gap-2">
            <LockKeyhole className="size-4 text-[#fcd535]" />
            Session protected
          </span>
        </div>
      </section>

      <main className="flex min-h-screen items-center justify-center p-5 sm:p-8">
        <Card className="w-full max-w-[440px] rounded-xl border-[#2b3139] bg-[#1e2329] p-2 text-[#eaecef] shadow-none">
        <CardHeader className="space-y-3 px-6 pt-7">
          <div className="mb-3 flex size-10 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20] lg:hidden">
            <Database className="size-5" />
          </div>
          <CardTitle className="text-2xl font-semibold tracking-tight text-white">
            Welcome back
          </CardTitle>
          <CardDescription className="text-sm text-[#929aa5]">
            Sign in to continue to DB Control
          </CardDescription>
        </CardHeader>

        <CardContent className="px-6 pb-7">
          <form onSubmit={handleSubmit}>
            <FieldGroup>
              <Field>
                <FieldLabel htmlFor="username">Username</FieldLabel>

                <Input
                  id="username"
                  name="username"
                  type="text"
                  value={formData.username}
                  onChange={handleChange}
                  disabled={loading}
                  className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
                />
              </Field>

              <Field>
                <FieldLabel htmlFor="password">Password</FieldLabel>

                <Input
                  id="password"
                  name="password"
                  type="password"
                  value={formData.password}
                  onChange={handleChange}
                  disabled={loading}
                  className="border-[#3f4650] bg-[#0b0e11] text-[#eaecef]"
                />
              </Field>

              {error && (
                <p role="alert" className="rounded-md border border-[#3f4650] bg-[#2b3139] px-3 py-2 text-sm text-[#eaecef]">
                  {error}
                </p>
              )}

              <Field>
                <Button
                  className="h-10 w-full"
                  type="submit"
                  disabled={loading}
                >
                  {loading ? <LoadingSpinner label="Logging in..." /> : "Login"}
                </Button>
              </Field>
            </FieldGroup>
          </form>
        </CardContent>
      </Card>
      </main>
    </div>
  );
};

export default Login;
