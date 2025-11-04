// This function should be tree-shaken when not used
export function unusedFunction() {
  console.assert("__unused__");
}

// This function is always used
export function usedFunction() {
  return "I'm used";
}
