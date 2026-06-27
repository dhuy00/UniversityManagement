import { Outlet } from "react-router-dom";
import AppSidebar from "../components/layout/AppSidebar";
import { SidebarProvider, SidebarTrigger } from "@/components/ui/sidebar";

export default function MainLayout() {
  return (
    <div className="flex h-screen box-border overflow-hidden bg-[#0b0e11] font-inter text-normal text-[#eaecef]">
      <SidebarProvider>
        <AppSidebar />
        <main className="min-w-0 flex-1 overflow-y-auto">
          <SidebarTrigger className="fixed left-3 top-6 z-40 border border-[#2b3139] bg-[#1e2329] text-[#eaecef] hover:bg-[#2b3139] md:hidden" />
          <Outlet />
        </main>
      </SidebarProvider>
    </div>
  );
}
