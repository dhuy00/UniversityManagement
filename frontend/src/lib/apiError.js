const genericValidationTitle = "One or more validation errors occurred.";

export function getApiErrorMessage(error, fallback) {
  const data = error?.response?.data;
  const validationMessages = data?.errors
    ? Object.values(data.errors)
      .flat()
      .filter((message) => typeof message === "string" && message.trim())
    : [];

  if (validationMessages.length > 0) {
    return [...new Set(validationMessages)].join(" ");
  }

  if (typeof data?.detail === "string" && data.detail.trim()) {
    return data.detail;
  }

  if (
    typeof data?.title === "string" &&
    data.title.trim() &&
    data.title !== genericValidationTitle
  ) {
    return data.title;
  }

  return fallback;
}
