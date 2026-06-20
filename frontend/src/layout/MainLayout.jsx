import { Outlet } from "react-router-dom";
import AppSidebar from "../components/layout/AppSidebar";
import { SidebarProvider } from "@/components/ui/sidebar";

export default function MainLayout() {
  return (
    <>
      <div className="flex font-inter h-screen box-border text-normal">
        <SidebarProvider>
          <AppSidebar />
          <main className="flex-1">
            <Outlet />
          </main>
        </SidebarProvider>
      </div>
    </>
  );
}
