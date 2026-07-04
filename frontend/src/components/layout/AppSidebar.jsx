import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarHeader,
} from "@/components/ui/sidebar";

import {
  BookOpen,
  Database,
  LayoutDashboard,
  LogOut,
  ShieldCheck,
  UserRound,
  Users,
} from "lucide-react";

import { useLocation, useNavigate } from "react-router-dom";
import {
  clearAuthSession,
  getAuthSession,
  isSystemAdministrator,
} from "@/lib/auth";
import { logout } from "@/api/authApi";

export default function AppSidebar() {
  const navigate = useNavigate();
  const location = useLocation();
  const session = getAuthSession();
  const username = session?.username || "Administrator";
  const initials = username.slice(0, 2).toUpperCase();

  const handleLogout = async () => {
    try {
      await logout();
    } catch {
      // Local sign-out must still complete if the session already expired.
    }
    clearAuthSession();
    navigate("/login", { replace: true });
  };

  const items = [
    {
      title: "Overview",
      url: "/",
      icon: LayoutDashboard,
    },
    {
      title: "My Profile",
      url: "/profile",
      icon: UserRound,
    },
    {
      title: "Courses",
      url: "/courses",
      icon: BookOpen,
    },
    ...(isSystemAdministrator(session)
      ? [
          {
            title: "Users",
            url: "/users",
            icon: Users,
          },
          {
            title: "Roles",
            url: "/roles",
            icon: ShieldCheck,
          },
        ]
      : []),
  ];

  return (
    <Sidebar className="border-r border-[#2b3139] bg-[#0b0e11]">
      <SidebarHeader className="border-b border-[#2b3139] p-4">
        <div className="flex h-10 items-center gap-3">
          <div className="flex size-9 items-center justify-center rounded-md bg-[#fcd535] text-[#181a20]">
            <Database className="size-5" />
          </div>
          <div className="flex flex-col">
            <span className="text-[15px] font-semibold tracking-tight text-white">
              DB Control
            </span>
            <span className="text-[11px] font-medium uppercase tracking-[0.12em] text-[#707a8a]">
              University Portal
            </span>
          </div>
        </div>
      </SidebarHeader>

      <SidebarContent>
        <SidebarGroup className="px-3 py-5">
          <SidebarGroupLabel className="mb-2 px-3 text-[11px] font-semibold uppercase tracking-[0.12em] text-[#707a8a]">
            Workspace
          </SidebarGroupLabel>

          <SidebarGroupContent>
            <SidebarMenu className="gap-1">
              {items.map((item) => (
                <SidebarMenuItem key={item.title}>
                  <SidebarMenuButton
                  
                    isActive={location.pathname === item.url}
                    onClick={() => navigate(item.url)}
                    className="h-10 cursor-pointer rounded-md px-3 text-[#929aa5] hover:bg-[#1e2329] hover:text-white data-[active]:bg-[#1e2329] data-[active]:font-semibold data-[active]:text-[#fcd535]"
                  >
                    <item.icon />
                    <span>{item.title}</span>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>

      <SidebarFooter className="border-t border-[#2b3139] p-3">
        <div className="mb-3 flex items-center gap-3 rounded-lg bg-[#1e2329] p-3">
          <div className="flex size-9 shrink-0 items-center justify-center rounded-full bg-[#2b3139] text-xs font-semibold text-[#fcd535]">
            {initials}
          </div>
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-semibold text-white">{username}</p>
            <p className="text-xs text-[#707a8a]">
              {session?.roleCode || session?.identityType}
            </p>
          </div>
        </div>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton
              className="h-10 cursor-pointer rounded-md border border-[#2b3139] bg-transparent text-[#929aa5] hover:bg-[#1e2329] hover:text-white"
              onClick={handleLogout}
            >
              <LogOut />
              <span>Sign out</span>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
    </Sidebar>
  );
}
