import { RiSkipRightLine } from "react-icons/ri";
import { MdOutlineNavigateNext } from "react-icons/md";

const Pagination = ({
  pages,
  currentPage,
  setCurrentPage,
}) => {
  const lastPage = pages.length;

  const handleFirstPage = () => {
    setCurrentPage(1);
  };

  const handleLastPage = () => {
    setCurrentPage(lastPage);
  };

  const handlePrevPage = () => {
    if (currentPage > 1) {
      setCurrentPage((prev) => prev - 1);
    }
  };

  const handleNextPage = () => {
    if (currentPage < lastPage) {
      setCurrentPage((prev) => prev + 1);
    }
  };

  return (
    <div className="absolute right-4 bottom-[4%] flex items-center text-xl text-text-secondary">
      {/* First */}
      <button
        onClick={handleFirstPage}
        disabled={currentPage === 1}
        className="disabled:opacity-40"
      >
        <RiSkipRightLine className="rotate-180 cursor-pointer hover:bg-background-primary py-0.5" />
      </button>

      {/* Prev */}
      <button
        onClick={handlePrevPage}
        disabled={currentPage === 1}
        className="disabled:opacity-40"
      >
        <MdOutlineNavigateNext className="rotate-180 cursor-pointer hover:bg-background-primary py-0.5" />
      </button>

      {/* Pages */}
      <div className="mx-2 flex gap-1">
        {pages.map((page) => (
          <button
            key={page}
            onClick={() => setCurrentPage(page)}
            className={`px-2 py-1 text-sm rounded cursor-pointer
            ${
              page === currentPage
                ? "bg-background-primary text-text-primary font-medium"
                : "hover:bg-background-primary"
            }`}
          >
            {page}
          </button>
        ))}
      </div>

      {/* Next */}
      <button
        onClick={handleNextPage}
        disabled={currentPage === lastPage}
        className="disabled:opacity-40"
      >
        <MdOutlineNavigateNext className="cursor-pointer hover:bg-background-primary py-0.5" />
      </button>

      {/* Last */}
      <button
        onClick={handleLastPage}
        disabled={currentPage === lastPage}
        className="disabled:opacity-40"
      >
        <RiSkipRightLine className="cursor-pointer hover:bg-background-primary py-0.5" />
      </button>
    </div>
  );
};

export default Pagination;