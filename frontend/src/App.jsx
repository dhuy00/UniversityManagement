import AppRoutes from "./routes";
import { Toaster } from "sonner";

function App() {
    return (
        <>
            <AppRoutes />
            <Toaster
              theme="dark"
              position="top-right"
              closeButton
              toastOptions={{
                classNames: {
                  toast: "!pr-12",
                },
                style: {
                  background: "#1e2329",
                  border: "1px solid #2b3139",
                  color: "#eaecef",
                },
              }}
            />
        </>
    );
}

export default App;
