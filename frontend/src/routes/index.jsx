import { Routes, Route } from "react-router-dom";

import MainLayout from "../layout/MainLayout"
import AuthLayout from "../layout/AuthLayout"

import ProtectedRoute from "./ProtectedRoute";
import RoleRoute from "./RoleRoute";
import SystemAdminRoute from "./SystemAdminRoute";
import Home from "../pages/Home";
import Profile from "../pages/Profile";
import Courses from "../pages/courses/Courses";
import CoursePlans from "../pages/course-plans/CoursePlans";
import TeachingAssignments from "../pages/teaching-assignments/TeachingAssignments";
import Enrollments from "../pages/enrollments/Enrollments";
import Forbidden from "../pages/Forbidden";
import Login from "../pages/auth/Login";
import Users from "../pages/users/Users";
import Roles from "../pages/roles/Roles";
import {
    ENROLLMENT_ROLES,
    TEACHING_ASSIGNMENT_ROLES,
} from "@/lib/roles";


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
                    <Route path="/profile" element={<Profile />} />
                    <Route path="/courses" element={<Courses />} />
                    <Route path="/course-plans" element={<CoursePlans />} />
                    <Route path="/forbidden" element={<Forbidden />} />
                    <Route element={<RoleRoute allowedRoles={TEACHING_ASSIGNMENT_ROLES} />}>
                        <Route
                            path="/teaching-assignments"
                            element={<TeachingAssignments />}
                        />
                    </Route>
                    <Route element={<RoleRoute allowedRoles={ENROLLMENT_ROLES} />}>
                        <Route path="/enrollments" element={<Enrollments />} />
                    </Route>
                    <Route element={<SystemAdminRoute />}>
                        <Route path="/users" element={<Users />} />
                        <Route path="/roles" element={<Roles />} />
                    </Route>
                </Route>
            </Route>
        </Routes>
    );
}
