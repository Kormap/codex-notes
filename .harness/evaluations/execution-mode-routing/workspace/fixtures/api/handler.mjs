export function responseStatus(error) {
  if (!error) return 200;
  if (error.code === 'NOT_FOUND') return 404;
  return 200;
}
