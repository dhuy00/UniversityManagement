import { AiOutlineDelete } from "react-icons/ai";
import { HiOutlineDocumentText } from "react-icons/hi2";
import { FiEdit3 } from "react-icons/fi";
import { mockUsers as users } from "../../mock/mockUsers";
import Pagination from "../common/Pagination";
import { useEffect, useState } from "react";

const fields = [
  {
    id: 1,
    name: "NO",
  },
  {
    id: 2,
    name: "NAME",
  },
  {
    id: 3,
    name: "ROLE",
  },
  {
    id: 4,
    name: "STATUS",
  },
  {
    id: 5,
    name: "LAST LOGIN",
  },
  {
    id: 6,
    name: "ACTION",
    className: "w-[10%]",
  },
];

export default function UserTable() {
  const ITEMS_PER_PAGE = 10;

  const [currentPage, setCurrentPage] = useState(1);

  const totalPages = Math.ceil(users.length / ITEMS_PER_PAGE);

  const pages = Array.from({ length: totalPages }, (_, index) => index + 1);

  const startIndex = (currentPage - 1) * ITEMS_PER_PAGE;

  const currentUsers = users.slice(startIndex, startIndex + ITEMS_PER_PAGE);

  useEffect(() => {
    console.log("current page: ", currentPage);
  }, [currentPage]);

  useEffect(() => {
    console.log("total pages: ", totalPages);
  }, [totalPages]);

  useEffect(() => {
    console.log("start index: ", startIndex);
  }, [startIndex]);

  useEffect(() => {
    console.log("currentUsers: ", currentUsers);
  }, [currentUsers]);

  return (
    <>
      <div className="overflow-hidden rounded-b-xl border border-border-primary bg-white">
        <div className="overflow-y-auto max-h-[500px]">
          <table className="w-full text-left">
            <thead className="sticky top-0 bg-gray-50">
              <tr>
                {fields.map((item) => (
                  <th
                    key={item.id}
                    className={`px-6 py-4 text-xs font-semibold uppercase tracking-wider text-gray-500 ${
                      item.className || ""
                    }`}
                  >
                    {item.name}
                  </th>
                ))}
              </tr>
            </thead>

            <tbody className="divide-y divide-gray-100">
              {currentUsers.map((user, index) => (
                <tr
                  key={user.id}
                  className="transition-colors hover:bg-gray-50"
                >
                  <td className="px-6 py-4 text-sm font-medium text-gray-900">
                    {user.id}
                  </td>

                  <td className="px-6 py-4 text-sm font-medium text-gray-900">
                    {user.name}
                  </td>

                  <td className="px-6 py-4 text-sm text-gray-600">
                    {user.role}
                  </td>

                  <td className="px-6 py-4">
                    <span
                      className={`inline-flex rounded-full px-2.5 py-1 text-xs font-medium ${
                        user.status === "Active"
                          ? "bg-green-100 text-green-700"
                          : "bg-red-100 text-red-700"
                      }`}
                    >
                      {user.status}
                    </span>
                  </td>

                  <td className="px-6 py-4 text-sm text-gray-600">
                    {user.lastLogin}
                  </td>

                  <td className="flex items-center gap-2 px-6 py-4 text-lg">
                    <button className="btn-action btn-detail">
                      <HiOutlineDocumentText />
                    </button>

                    <button className="btn-action btn-edit">
                      <FiEdit3 />
                    </button>

                    <button className="btn-action btn-delete">
                      <AiOutlineDelete />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <Pagination
        pages={pages}
        currentPage={currentPage}
        setCurrentPage={setCurrentPage}
      />
    </>
  );
}
