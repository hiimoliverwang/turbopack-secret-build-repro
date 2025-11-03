export function assertPrune() {
  console.assert('__ant_only__');

  if (!process.env.NEXT_PUBLIC_INCLUDE_SECRET_STUFF) {
    throw new Error('NEXT_PUBLIC_INCLUDE_SECRET_STUFF environment variable is not set');
  }
}
