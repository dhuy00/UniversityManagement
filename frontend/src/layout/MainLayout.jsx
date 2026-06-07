import { Outlet } from "react-router-dom";
import Sidebar from "../components/layout/Sidebar";

export default function MainLayout() {
  return (
    <>
      <div className="flex font-inter h-screen box-border text-normal">
        <Sidebar />
        <main className="flex-1">
          <Outlet />
        </main>
      </div>
    </>
  );
}
