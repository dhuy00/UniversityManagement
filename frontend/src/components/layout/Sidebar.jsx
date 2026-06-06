import React, { useState } from "react";
import { FaUser } from "react-icons/fa";
import { FaShieldAlt } from "react-icons/fa";
import { IoIosSettings } from "react-icons/io";
import { IoLogOutOutline } from "react-icons/io5";
import { useNavigate } from "react-router-dom";

const Sidebar = () => {
  const [activeLink, setActiveLink] = useState(1);
  const navigate = useNavigate();

  const sideBarLink = [
    {
      id: 1,
      text: "Users",
      url: "/users",
      icon: <FaUser />,
    },
    {
      id: 2,
      text: "Roles",
      url: "/roles",
      icon: <FaShieldAlt />,
    },
    {
      id: 3,
      text: "Settings",
      url: "/settings",
      icon: <IoIosSettings />,
    },
  ];

  const handleOpenLink = (link) => {
    setActiveLink(link.id);
    navigate(link.url);
  };

  const handleLogout = () => {
    navigate("/logout")
  }

  return (
    <div
      className="w-[252px] h-full bg-background-primary border border-border-primary flex flex-col
    text-normal justify-between"
    >
      <div>
        <div className="flex gap-2 h-14 items-center border-b border-border-primary px-3">
          <span
            className="w-10 h-10 bg-background-tertiary rounded-full flex justify-center items-center
        text-text-tertiary font-semibold"
          >
            <span>EC</span>
          </span>
          <div className="flex flex-col">
            <span className=" text-text-primary font-semibold">Emily Chen</span>
            <span className="text-small text-text-subtitle">Administrator</span>
          </div>
        </div>
        <div className="flex flex-col px-3 pt-4 gap-2">
          {sideBarLink.map((link) => (
            <div
              key={link.id}
              onClick={() => handleOpenLink(link)}
              className={`flex items-center gap-2 text-normal py-3 px-3 rounded-lg cursor-pointer transition-colors
      ${
        activeLink === link.id
          ? "bg-background-tertiary text-text-tertiary shadow-small"
          : "text-text-secondary hover:bg-background-tertiary hover:text-text-tertiary hover:shadow-small"
      }`}
            >
              <span>{link.icon}</span>
              <span>{link.text}</span>
            </div>
          ))}
        </div>
      </div>
      <div className="flex items-center px-4 gap-2 text-text-secondary py-3.5 border-t border-border-primary font-medium"
      onClick={() => handleLogout()}>
        <IoLogOutOutline className="text-lg" />
        <span>Sign out</span>
      </div>
    </div>
  );
};

export default Sidebar;
