import { Routes, Route } from "react-router-dom";

import MainLayout from "../layout/MainLayout"
import AuthLayout from "../layout/AuthLayout"

import ProtectedRoute from "./ProtectedRoute";
import SystemAdminRoute from "./SystemAdminRoute";
import Home from "../pages/Home";
import Forbidden from "../pages/Forbidden";
import Login from "../pages/auth/Login";
import Users from "../pages/users/Users";
import Roles from "../pages/roles/Roles";


export default function AppRoutes() {
    return (
        <Routes>
            {/* Auth Routes */}
            <Route element={<AuthLayout />}>
                <Route path="/login" element={<Login />} />
            </Route>

            {/* Protected Routes */}
            <Route element={<ProtectedRoute />}>
                <Route element={<MainLayout />}>
                    <Route path="/" element={<Home />} />
                    <Route path="/forbidden" element={<Forbidden />} />
                    <Route element={<SystemAdminRoute />}>
                        <Route path="/users" element={<Users />} />
                        <Route path="/roles" element={<Roles />} />
                    </Route>
                </Route>
            </Route>
        </Routes>
    );
}
