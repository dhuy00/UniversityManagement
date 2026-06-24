import AppRoutes from "./routes";
import { Toaster } from "sonner";

function App() {
    return (
        <>
            <AppRoutes />
            <Toaster richColors position="top-right" />
        </>
    );
}

export default App;
