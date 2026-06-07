const users = [
  {
    id: 1,
    name: "John Doe",
    email: "john@example.com",
    role: "Admin",
    status: "Active",
    lastLogin: '23-May-26 13:40:32'
  },
  {
    id: 2,
    name: "John Doe",
    email: "john@example.com",
    role: "Admin",
    status: "Active",
    lastLogin: '23-May-26 13:40:32'
  },
  {
    id: 3,
    name: "John Doe",
    email: "john@example.com",
    role: "Admin",
    status: "Active",
    lastLogin: '23-May-26 13:40:32'
  },
  
];

const fields = [
  {
    id: 1,
    name: "NO",
    className: "",
  },
  {
    id: 2,
    name: "NAME",
    className: "",
  },
  {
    id: 3,
    name: "ROLE",
    className: "",
  },
  {
    id: 4,
    name: "STATUS",
    className: "",
  },
  {
    id: 5,
    name: "LAST LOGIN",
    className: "",
  },
  {
    id: 6,
    name: "ACTION",
    className: "",
  },
];

export default function UserTable() {
  return (
    <div className="overflow-hidden rounded-b-xl border border-border-primary bg-white">
      <div className="overflow-x-auto">
        <table className="w-full text-left">
          <thead className="bg-gray-50">
            <tr>
              {fields.map((item) => (
                <th className={`px-6 py-4 text-xs font-semibold uppercase tracking-wider text-gray-500
                ${item.className}`}>
                  {item.name}
                </th>
              ))}
            </tr>
          </thead>

          <tbody className="divide-y divide-gray-100">
            {users.map((user, index) => (
              <tr key={user.id} className="transition-colors hover:bg-gray-50">
                <td className="px-6 py-4 text-sm font-medium text-gray-900">
                  {index}
                </td>
                <td className="px-6 py-4 text-sm font-medium text-gray-900">
                  {user.name}
                </td>

                <td className="px-6 py-4 text-sm text-gray-600">
                  {user.email}
                </td>

                <td className="px-6 py-4 text-sm text-gray-600">{user.role}</td>

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
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
