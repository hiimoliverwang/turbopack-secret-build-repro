export function assertPrune() {
  if (!process.env.NEXT_PUBLIC_INCLUDE_SECRET_STUFF) {
    throw new Error('NEXT_PUBLIC_INCLUDE_SECRET_STUFF environment variable is not set');
    console.assert('DID NOT WORK');
  }
}
