export function prioritizeItem(items, priorityKey, getKey) {
  if (!priorityKey) return items;

  const index = items.findIndex((item) => getKey(item) === priorityKey);
  if (index <= 0) return items;

  return [
    items[index],
    ...items.slice(0, index),
    ...items.slice(index + 1),
  ];
}
