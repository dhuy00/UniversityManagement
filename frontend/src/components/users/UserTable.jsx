import { useState } from "react";

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";

import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

import { Button } from "@/components/ui/button";

import {
  MoreHorizontal,
  Pencil,
  Trash2,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";

const users = [
  {
    id: 1,
    name: "John Doe",
    email: "john@gmail.com",
    role: "Admin",
    status: "active",
    avatar: "https://i.pravatar.cc/150?img=1",
    lastLogin: "3 hours ago",
  },
  {
    id: 2,
    name: "Jane Smith",
    email: "jane@gmail.com",
    role: "User",
    status: "active",
    avatar: "https://i.pravatar.cc/150?img=2",
    lastLogin: "3 hours ago",
  },
  {
    id: 3,
    name: "Michael Lee",
    email: "michael@gmail.com",
    role: "Manager",
    status: "active",
    avatar: "https://i.pravatar.cc/150?img=3",
    lastLogin: "3 hours ago",
  },
  {
    id: 4,
    name: "Sarah Wilson",
    email: "sarah@gmail.com",
    role: "User",
    status: "inactive",
    avatar: "https://i.pravatar.cc/150?img=4",
    lastLogin: "3 hours ago",
  },
  {
    id: 5,
    name: "David Brown",
    email: "david@gmail.com",
    role: "Admin",
    status: "inactive",
    avatar: "https://i.pravatar.cc/150?img=5",
    lastLogin: "3 hours ago",
  },
  {
    id: 6,
    name: "Emma Taylor",
    email: "emma@gmail.com",
    role: "User",
    status: "active",
    avatar: "https://i.pravatar.cc/150?img=6",
    lastLogin: "3 hours ago",
  },
];

const ITEMS_PER_PAGE = 5;

export default function UserTable() {
  const [page, setPage] = useState(1);

  const totalPages = Math.ceil(users.length / ITEMS_PER_PAGE);

  const currentUsers = users.slice(
    (page - 1) * ITEMS_PER_PAGE,
    page * ITEMS_PER_PAGE,
  );

  const getRoleVariant = (role) => {
    switch (role) {
      case "inactive":
        return "secondary";
      default:
        return "default";
    }
  };

  const handleEdit = (user) => {
    console.log("Edit:", user);
  };

  const handleDelete = (user) => {
    console.log("Delete:", user);
  };

  return (
    <div className="space-y-4">
      <div className="rounded-b-lg border bg-background">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>ID</TableHead>
              <TableHead>USERNAME</TableHead>
              <TableHead>ROLE</TableHead>
              <TableHead>STATUS</TableHead>
              <TableHead>LAST LOGIN</TableHead>
              <TableHead className="w-[80px] text-center">Actions</TableHead>
            </TableRow>
          </TableHeader>

          <TableBody>
            {currentUsers.map((user) => (
              <TableRow key={user.id}>
                <TableCell>
                  <div className="flex items-center gap-3">
                    <div>
                      <p className="font-medium">{user.id}</p>
                    </div>
                  </div>
                </TableCell>

                <TableCell>{user.name}</TableCell>

                <TableCell>{user.role}</TableCell>

                <TableCell>
                  <Badge variant={getRoleVariant(user.status)}>
                    {user.status}
                  </Badge>
                </TableCell>

                <TableCell>{user.lastLogin}</TableCell>

                <TableCell className="text-right">
                  <div className="flex items-center justify-end gap-1">
                    <Button
                    className={`bg-stone-100 hover:bg-stone-200`}
                      variant="ghost"
                      size="icon"
                      onClick={() => handleEdit(user)}
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>

                    <Button
                      variant="ghost"
                      size="icon"
                      className="text-red-500 hover:text-red-600 hover:bg-red-200 bg-red-100"
                      onClick={() => handleDelete(user)}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">
          Page {page} of {totalPages}
        </p>

        <div className="flex gap-2">
          <Button
            variant="outline"
            size="icon"
            disabled={page === 1}
            onClick={() => setPage((prev) => prev - 1)}
          >
            <ChevronLeft size={16} />
          </Button>

          <Button
            variant="outline"
            size="icon"
            disabled={page === totalPages}
            onClick={() => setPage((prev) => prev + 1)}
          >
            <ChevronRight size={16} />
          </Button>
        </div>
      </div>
    </div>
  );
}
