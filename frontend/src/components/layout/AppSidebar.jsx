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

import { FaUser, FaShieldAlt } from "react-icons/fa";
import { IoIosSettings } from "react-icons/io";
import { IoLogOutOutline } from "react-icons/io5";

import { useLocation, useNavigate } from "react-router-dom";

export default function AppSidebar() {
  const navigate = useNavigate();
  const location = useLocation();

  const items = [
    {
      title: "Users",
      url: "/users",
      icon: FaUser,
    },
    {
      title: "Roles",
      url: "/roles",
      icon: FaShieldAlt,
    },
    {
      title: "Settings",
      url: "/settings",
      icon: IoIosSettings,
    },
  ];

  return (
    <Sidebar className={`bg-red-400`}>
      <SidebarHeader>
        <div className="flex gap-3 items-center px-2 py-2 border-b">
          <div className="size-10 rounded-full bg-slate-300 flex items-center justify-center font-semibold">
            EC
          </div>

          <div className="flex flex-col">
            <span className="font-semibold">Emily Chen</span>
            <span className="text-xs text-muted-foreground">
              Administrator
            </span>
          </div>
        </div>
      </SidebarHeader>

      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>Admin Panel</SidebarGroupLabel>

          <SidebarGroupContent>
            <SidebarMenu className={`gap-2`}>
              {items.map((item) => (
                <SidebarMenuItem key={item.title}>
                  <SidebarMenuButton
                  
                    isActive={location.pathname === item.url}
                    onClick={() => navigate(item.url)}
                    className={`h-10 py-2 data-[active]:bg-background-tertiary data-[active]:text-white cursor-pointer`}
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

      <SidebarFooter className={``}>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton
            className={`border border-red-600 bg-background text-red-600 h-10 hover:bg-red-100
              hover:text-red-600`}
              onClick={() => navigate("/logout")}
            >
              <IoLogOutOutline />
              <span>Sign out</span>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
    </Sidebar>
  );
}